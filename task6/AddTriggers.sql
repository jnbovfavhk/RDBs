-- Для INSERT
-- 1
-- Представление таблицы доставок
CREATE OR REPLACE VIEW "DeliveriesView" AS
SELECT * FROM "Deliveries";

-- Функция, которая вместо простой вставки строки в "Deliveries", проверяет срок годности и обновляет склад
CREATE OR REPLACE FUNCTION process_delivery_instead_of()
RETURNS TRIGGER AS $$
DECLARE
    last_quantity INTEGER;
	min_expiry_days INTEGER := 3;
BEGIN


	-- Проверка срока годности
    IF NEW."Expiration_date" IS NOT NULL THEN
        -- Проверяем, что срок годности не истек и есть запас минимум на 3 дня
        IF NEW."Expiration_date" < CURRENT_DATE THEN
            RAISE EXCEPTION 'Продукт с истекшим сроком годности не может быть поставлен (срок: %)', NEW."Expiration_date";
        ELSIF NEW."Expiration_date" < CURRENT_DATE + min_expiry_days THEN
            RAISE EXCEPTION 'Срок годности продукта заканчивается слишком скоро (осталось менее % дней)', min_expiry_days;
        END IF;
    END IF;


    -- Вставляем запись в таблицу Deliveries
    INSERT INTO "Deliveries" (
        "consignment_note_id",
        "Arrival_date",
        "supplier_id",
        "product_id",
        "Quantity",
        "Expiration_date"
    ) VALUES (
        NEW."consignment_note_id",
        NEW."Arrival_date",
        NEW."supplier_id",
        NEW."product_id",
        NEW."Quantity",
        NEW."Expiration_date"
    );
    
    -- Находим последнее количество товара на складе
    SELECT "Quantity_in_stock" INTO last_quantity
    FROM "WarehouseStatus"
    WHERE "product_id" = NEW."product_id"
    LIMIT 1;
    
    -- Если записи о товаре нет, считаем что было 0
    IF last_quantity IS NULL THEN
        last_quantity := 0;
    END IF;
    
    -- Обновляем склад
    INSERT INTO "Warehouse" (
        "product_id", 
        "Quantity_in_stock", 
        "Date", 
        "Warehouse_type"
    )
    VALUES (
        NEW."product_id",
        last_quantity + NEW."Quantity",
        NEW."Arrival_date",
        'Основной'
    )
    ON CONFLICT ("product_id") 
    DO UPDATE SET
        "Quantity_in_stock" = EXCLUDED."Quantity_in_stock",
        "Date" = EXCLUDED."Date";
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- INSTEAD OF триггер для INSERT в представление
CREATE TRIGGER instead_of_insert_delivery
INSTEAD OF INSERT ON "DeliveriesView"
FOR EACH ROW EXECUTE FUNCTION process_delivery_instead_of();


-- 2
-- Функция для обновления уровня скидки клиента при добавлении продажи
CREATE OR REPLACE FUNCTION update_client_discount_on_sale()
RETURNS TRIGGER AS $$
DECLARE
    client_id_var INTEGER;
    current_discount SMALLINT;
    total_orders_var INTEGER;
    total_spent_var NUMERIC;
BEGIN
    -- Получаем client_id из связанного чека
    SELECT r."client_id" INTO client_id_var
    FROM "Receipts" r
    WHERE r."receipt_id" = NEW."receipt_id";
    
    -- Если чек без клиента, выходим
    IF client_id_var IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Вычисляем общее количество заказов и сумму
    SELECT 
        COUNT(r."receipt_id"),
        COALESCE(SUM(r."Receipt_amount"), 0)
    INTO total_orders_var, total_spent_var
    FROM "Receipts" r
    WHERE r."client_id" = client_id_var;
    
    -- Логика расчета скидки
    IF total_spent_var > 50000 THEN
        current_discount := 3;
    ELSIF total_spent_var > 20000 THEN
        current_discount := 2;
    ELSIF total_orders_var > 3 THEN
        current_discount := 1;
    ELSE
        current_discount := 0;
    END IF;
    
    -- Обновление скидки клиента
    UPDATE "Clients"
    SET "Discount_level" = current_discount
    WHERE "client_id" = client_id_var;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- AFTER INSERT триггер для таблицы Sales
CREATE TRIGGER check_client_discount_after_sale
AFTER INSERT ON "Sales"
FOR EACH ROW EXECUTE FUNCTION update_client_discount_on_sale();


-- для UPDATE
-- 1
-- Представление клиентов с количеством заказов и потраченных денег
CREATE VIEW clients_discount_view AS
SELECT c."client_id", c."Discount_level", c."Card_number", c."Phone_number",
       COUNT(r."receipt_id") AS total_orders,
       SUM(r."Receipt_amount") AS total_spent
FROM "Clients" c
LEFT JOIN "Receipts" r ON c."client_id" = r."client_id"
GROUP BY c."client_id";

-- Функция для обновления уровня скидки
CREATE OR REPLACE FUNCTION update_client_discount()
RETURNS TRIGGER AS $$
BEGIN
    -- Автоматически рассчитываем уровень скидки на основе истории заказов
    IF NEW."total_spent" > 50000 THEN
        NEW."Discount_level" = 3;
    ELSIF NEW."total_spent" > 20000 THEN
        NEW."Discount_level" = 2;
    ELSIF NEW."total_orders" > 3 THEN
        NEW."Discount_level" = 1;
    ELSE
        NEW."Discount_level" = 0;
    END IF;
    
    -- Обновляем данные клиента
    UPDATE "Clients"
    SET "Discount_level" = NEW."Discount_level",
        "Card_number" = NEW."Card_number",
        "Phone_number" = NEW."Phone_number"
    WHERE "client_id" = NEW."client_id";
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- INSTEAD OF триггер для обновления представления
CREATE TRIGGER client_discount_trigger
INSTEAD OF UPDATE ON clients_discount_view
FOR EACH ROW EXECUTE FUNCTION update_client_discount();


-- 2
-- при изменении(INSERT, DELETE, UPDATE) сумм продаж в "Sales" изменения автоматически совершаются и в таблице "Receipts"
CREATE OR REPLACE FUNCTION update_receipt_amount()
RETURNS TRIGGER AS $$
BEGIN
    -- Определяем ID чека, который нужно обновить
    DECLARE
        target_receipt_id INTEGER;
    BEGIN
        -- Для операции INSERT/UPDATE берем receipt_id из новой записи
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            target_receipt_id := NEW.receipt_id;
        -- Для операции DELETE берем receipt_id из старой записи
        ELSIF (TG_OP = 'DELETE') THEN
            target_receipt_id := OLD.receipt_id;
        END IF;
        
        -- Обновляем сумму в чеке, суммируя все связанные продажи
        UPDATE "Receipts" 
        SET "Receipt_amount" = (
            SELECT COALESCE(SUM("Sale_amount"), 0)
            FROM "Sales" 
            WHERE "receipt_id" = target_receipt_id
        )
        WHERE "receipt_id" = target_receipt_id;
    END;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- AFTER триггер для всех операций
CREATE TRIGGER sales_change_trigger
AFTER INSERT OR UPDATE OR DELETE ON "Sales"
FOR EACH ROW EXECUTE FUNCTION update_receipt_amount();


-- для DELETE
-- 1
-- Функция, чтобы при удалении блюда удаляются все записи с этим блюдом в Allergens_and_dishes
CREATE OR REPLACE FUNCTION delete_dish_relations()
RETURNS TRIGGER AS $$
BEGIN
    -- Удаляем все связи этого блюда с аллергенами
    DELETE FROM "Allergens_and_dishes"
    WHERE "dish_id" = OLD."dish_id";
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- AFTER DELETE триггер
CREATE TRIGGER after_dish_delete
AFTER DELETE ON "Dishes"
FOR EACH ROW EXECUTE FUNCTION delete_dish_relations();


-- 2
-- Функция: при удалении блюда удаляются связанные с ним строки в Dishes_and_Ingredients
CREATE OR REPLACE FUNCTION delete_dish_ingredients()
RETURNS TRIGGER AS $$
BEGIN
    -- Удаляем все связанные ингредиенты блюда
    DELETE FROM "Dishes_and_Ingredients"
    WHERE "dish_id" = OLD."dish_id";
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- AFTER DELETE триггер
CREATE OR REPLACE TRIGGER after_dish_delete
AFTER DELETE ON "Dishes"
FOR EACH ROW EXECUTE FUNCTION delete_dish_ingredients();


-- 3
-- Представление для чеков
CREATE OR REPLACE VIEW receipts_view AS
SELECT * FROM "Receipts";

-- Функция, чтобы удалять свзянные с чеком продажи при удалении чека
CREATE OR REPLACE FUNCTION delete_receipt_with_sales()
RETURNS TRIGGER AS $$
BEGIN
    -- Сначала удаляем все связанные продажи
    DELETE FROM "Sales" 
    WHERE "receipt_id" = OLD."receipt_id";
    
    -- Затем удаляем сам чек
    DELETE FROM "Receipts" 
    WHERE "receipt_id" = OLD."receipt_id";
    
    -- Возвращаем удаленную запись
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- INSTEAD OF DELETE триггер
CREATE TRIGGER instead_of_receipt_delete
INSTEAD OF DELETE ON receipts_view
FOR EACH ROW EXECUTE FUNCTION delete_receipt_with_sales();
