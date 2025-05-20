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

-- Тесты
-- 1: Попытка вставить поставку с истекшим сроком годности (должна вызвать ошибку)
INSERT INTO "DeliveriesView" (
    "consignment_note_id",
    "Arrival_date",
    "supplier_id",
    "product_id",
    "Quantity",
    "Expiration_date"
) VALUES (
    213498,
    CURRENT_DATE,
    1,
    1,
    10,
    CURRENT_DATE - 1  -- Вчерашняя дата
);



-- 2: Попытка вставить поставку с истекающим сроком годности (менее 3 дней, должна вызвать ошибку)

INSERT INTO "DeliveriesView" (
    "consignment_note_id",
    "Arrival_date",
    "supplier_id",
    "product_id",
    "Quantity",
    "Expiration_date"
) VALUES (
    2395798,
    CURRENT_DATE,
    1,
    1,
    10,
    CURRENT_DATE + 2
);



-- 3: Успешная вставка поставки с нормальным сроком годности и проверка обновления склада

-- Проверяем текущее количество на складе
SELECT "Quantity_in_stock" FROM "WarehouseStatus" WHERE "product_id" = 1;

-- Вставляем новую поставку
INSERT INTO "DeliveriesView" (
    "consignment_note_id",
    "Arrival_date",
    "supplier_id",
    "product_id",
    "Quantity",
    "Expiration_date"
) VALUES (
    'TEST-003',
    CURRENT_DATE,
    1,
    1,
    15,
    CURRENT_DATE + 30  -- Нормальный срок
);

-- Проверяем обновленное количество на складе
SELECT "Quantity_in_stock" FROM "WarehouseStatus" WHERE "product_id" = 1;




-- 2
-- Функция для обновления уровня скидки клиента при добавлении продажи

CREATE OR REPLACE FUNCTION public.update_client_discount_on_sale_change()
RETURNS trigger AS $$
DECLARE
    client_id_var INTEGER;
    current_discount SMALLINT;
    total_orders_var INTEGER;
    total_spent_var NUMERIC;
BEGIN
    -- Для DELETE получаем client_id из удаляемой записи
    IF TG_OP = 'DELETE' THEN
        SELECT r."client_id" INTO client_id_var
        FROM "Receipts" r
        WHERE r."receipt_id" = OLD."receipt_id";
    ELSE
        -- Для INSERT/UPDATE получаем client_id из новой записи
        SELECT r."client_id" INTO client_id_var
        FROM "Receipts" r
        WHERE r."receipt_id" = NEW."receipt_id";
    END IF;
    
    -- Если чек без клиента, выходим
    IF client_id_var IS NULL THEN
        RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
    END IF;
    
    -- Пересчитываем общее количество заказов и сумму (учитывая удаленные записи)
    SELECT 
        COUNT(r."receipt_id"),
        COALESCE(SUM(r."Receipt_amount"), 0)
    INTO total_orders_var, total_spent_var
    FROM "Receipts" r
    WHERE r."client_id" = client_id_var
    AND EXISTS (SELECT 1 FROM "Sales" s WHERE s."receipt_id" = r."receipt_id");
    
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
    
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$ LANGUAGE plpgsql;

-- AFTER INSERT OR DELETE OR UPDATE триггер для таблицы Sales
CREATE OR REPLACE TRIGGER check_client_discount_on_sale_change
AFTER INSERT OR DELETE OR UPDATE ON "Sales"
FOR EACH ROW EXECUTE FUNCTION update_client_discount_on_sale_change();


INSERT INTO "Clients" (client_id, "Discount_level", "Card_number", "Phone_number") VALUES 
(9999956, 0, 2345456732443750, 79351993754);

SELECT * FROM "Clients" 
WHERE client_id = 9999956;

INSERT INTO "Receipts"(receipt_id, "Date", "Time", client_id, "Receipt_amount", "Payment_type") VALUES
(100345, CURRENT_DATE, CURRENT_TIME, 9999956, 1200, 'Карта'),
(100324, CURRENT_DATE, CURRENT_TIME, 9999956, 1200, 'Карта'),
(100346, CURRENT_DATE, CURRENT_TIME, 9999956, 1200, 'Карта'),
(100347, CURRENT_DATE, CURRENT_TIME, 9999956, 1200, 'Карта');


INSERT INTO "Sales"(dish_id, receipt_id, "Sale_amount") VALUES
(4, 100345, 1200),
(78, 100324, 1200),
(4, 100346, 1200),
(4, 100347, 1200);

-- Проверка уровня скидок(должен быть 1 так как количество чеков >3)
SELECT * FROM "Clients" 
WHERE client_id = 9999956;

INSERT INTO "Sales"(dish_id, receipt_id, "Sale_amount") VALUES
(4, 100345, 20000);

-- Должен быть 2 потому что сумма чеков >20000 
SELECT * FROM "Clients" 
WHERE client_id = 9999956;

INSERT INTO "Sales"(dish_id, receipt_id, "Sale_amount") VALUES
(80, 100347, 40000);

-- Должен быть 3
SELECT * FROM "Clients" 
WHERE client_id = 9999956;


-- 3
-- Проверка на уникальность имени блюда
CREATE OR REPLACE FUNCTION check_dish_name_uniqueness()
RETURNS TRIGGER AS $$
DECLARE
    normalized_name TEXT;
    exists_count INTEGER;
BEGIN
    -- Нормализуем имя блюда: удаляем лишние пробелы и приводим к lowercase
    normalized_name := LOWER(TRIM(REGEXP_REPLACE(NEW."Name", '\s+', ' ', 'g')));
    
    -- Проверяем, существует ли уже блюдо с таким именем
    -- Для UPDATE исключаем из проверки текущую запись
    SELECT COUNT(*) INTO exists_count
    FROM "Dishes"
    WHERE LOWER(TRIM(REGEXP_REPLACE("Name", '\s+', ' ', 'g'))) = normalized_name
    AND (TG_OP = 'INSERT' OR dish_id <> NEW.dish_id);
    
    -- Если нашли совпадение (кроме текущей записи при UPDATE)
    IF exists_count > 0 THEN
        RAISE EXCEPTION 'Блюдо с именем "%" уже существует', normalized_name;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- BEFORE триггер
CREATE TRIGGER ensure_dish_name_unique
BEFORE INSERT OR UPDATE OF "Name" ON "Dishes"
FOR EACH ROW EXECUTE FUNCTION check_dish_name_uniqueness();

-- Тест(Ошибка)
INSERT INTO "Dishes"("Name", "Type", "Calories", "Price") VALUES
('Салат ЦезаРь  ', 'Салат', 300, 400);


-- для UPDATE
-- 1
-- Валидация карты и номера телефона(только российские)
CREATE OR REPLACE FUNCTION validate_client_data()
RETURNS TRIGGER AS $$
BEGIN
    
	-- Проверяем, изменились ли интересующие нас поля
    -- Для операции INSERT всегда проверяем
    IF TG_OP = 'INSERT' OR 
       (TG_OP = 'UPDATE' AND (
           (NEW."Phone_number" IS DISTINCT FROM OLD."Phone_number") OR
           (NEW."Card_number" IS DISTINCT FROM OLD."Card_number")
       )) THEN

	    IF NEW."Phone_number" IS NOT NULL THEN
	        -- Проверка, что номер начинается с 7 и имеет 11 цифр
	        IF NOT (NEW."Phone_number" >= 70000000000 AND NEW."Phone_number" <= 79999999999) THEN
	            RAISE EXCEPTION 'Некорректный номер телефона. Номер должен начинаться с 7 и содержать 11 цифр. Пример: 79161234567';
	        END IF;
	    END IF;
	    
	    -- Валидация номера карты
	    IF NEW."Card_number" IS NOT NULL THEN
	        -- Проверка, что номер карты состоит из 16 цифр
	        IF NOT (NEW."Card_number" >= 1000000000000000 AND NEW."Card_number" <= 9999999999999999) THEN
	            RAISE EXCEPTION 'Некорректный номер карты. Номер должен содержать ровно 16 цифр. Пример: 1234567890123456';
	        END IF;
	    END IF;
	END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- BEFORE триггер
CREATE OR REPLACE TRIGGER validate_client_update
BEFORE UPDATE OR INSERT ON "Clients"
FOR EACH ROW EXECUTE FUNCTION validate_client_data();

-- Ошибка
UPDATE "Clients" SET "Phone_number" = 4567
WHERE client_id = 10;

-- Ошибка
UPDATE "Clients" SET "Card_number" = 45672346958630914389246
WHERE client_id = 10;

-- Ошибка
UPDATE "Clients" SET "Phone_number" = 45673546543
WHERE client_id = 10;

-- Без ошибок
UPDATE "Clients" SET "Phone_number" = 74562850912
WHERE client_id = 10;


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


-- Тест
SELECT * FROM "Receipts"
WHERE receipt_id = 100;

INSERT INTO "Sales"(dish_id, receipt_id, "Sale_amount") VALUES
(80, 100, 2000);

SELECT * FROM "Receipts"
WHERE receipt_id = 100;



-- 3
-- При замене длолжности сотрудника его опыт меняется или на тот, который был передан, или на больший на год
-- Представление
CREATE OR REPLACE VIEW employees_view AS
SELECT * FROM "Employees";

-- Функция
CREATE OR REPLACE FUNCTION update_employee_position_instead()
RETURNS TRIGGER AS $$
BEGIN
    -- Если должность изменилась И новый опыт не указан (равен старому)
    IF NEW."Position" IS DISTINCT FROM OLD."Position" AND 
       NEW."Experience" = OLD."Experience" THEN
        -- Увеличиваем опыт на 1 год
        NEW."Experience" := OLD."Experience" + 1;
    END IF;
    
    -- Если опыт указан явно - оставляем как есть
    
    
    UPDATE "Employees" SET
        "Position" = NEW."Position",
        "Full_name" = NEW."Full_name",
        "Experience" = NEW."Experience",
        "Phone_number" = NEW."Phone_number",
        "Salary" = NEW."Salary"
    WHERE "employee_id" = OLD."employee_id";
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер
CREATE TRIGGER employees_position_update
INSTEAD OF UPDATE ON employees_view
FOR EACH ROW
EXECUTE FUNCTION update_employee_position_instead();

-- Тест
-- Смотрим опыт
SELECT * FROM employees_view
WHERE employee_id = 24;

-- Меняем должность
UPDATE employees_view 
SET "Position" = 'Директор'
WHERE employee_id = 24;

-- Опыт увеличился на 1
SELECT * FROM employees_view
WHERE employee_id = 24;



-- для DELETE
-- 1 Вместо удаления сотрудников из Employees будем переносить их в таблицу с бывшими сторудниками
CREATE TABLE "FormerEmployees" (
    "employee_id" INTEGER PRIMARY KEY,
    "Position" TEXT NOT NULL,
    "Full_name" TEXT NOT NULL,
    "Experience" SMALLINT NOT NULL,
    "Phone_number" BIGINT NOT NULL,
    "Salary" INTEGER,
    "Termination_date" DATE NOT NULL DEFAULT CURRENT_DATE,
    "Termination_reason" TEXT
);

-- Представление
CREATE OR REPLACE VIEW employees_view AS
SELECT * FROM "Employees";

-- Функция
CREATE OR REPLACE FUNCTION archive_employee_instead()
RETURNS TRIGGER AS $$
DECLARE
    termination_reason TEXT := 'По собственному желанию';
BEGIN

	BEGIN
        termination_reason := current_setting('terminal.reason');
    EXCEPTION WHEN undefined_object THEN
        termination_reason := 'По собственному желанию'; -- По умолчанию
    END;


	-- Обновляем ссылки на поваров в Sales перед удалением
    UPDATE "Sales" SET "cook_id" = NULL 
    WHERE "cook_id" = OLD."employee_id";

	-- -- Обновляем ссылки на официантов в Receipts перед удалением
    UPDATE "Receipts" SET "waiter_id" = NULL 
    WHERE "waiter_id" = OLD."employee_id";

	
    -- Переносим сотрудника в таблицу бывших сотрудников
    INSERT INTO "FormerEmployees" (
        "employee_id",
        "Position",
        "Full_name",
        "Experience",
        "Phone_number",
        "Salary",
        "Termination_reason"
    ) VALUES (
        OLD."employee_id",
        OLD."Position",
        OLD."Full_name",
        OLD."Experience",
        OLD."Phone_number",
        OLD."Salary",
        termination_reason
    );
    
    -- Удаляем из основной таблицы
    DELETE FROM "Employees"
    WHERE "employee_id" = OLD."employee_id";
    

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER archive_employee_instead_of_delete
INSTEAD OF DELETE ON employees_view
FOR EACH ROW
EXECUTE FUNCTION archive_employee_instead();

-- Тест
SELECT * FROM "Receipts" r 
WHERE waiter_id = 46;

DELETE FROM employees_view WHERE "employee_id" = 46;

-- Проверяем, что в таблице Receipts теперь NULL
SELECT * FROM "Receipts" r 
WHERE waiter_id = 46;


-- Увольняем по другой причине
SELECT * FROM "Employees" 
WHERE employee_id = 92;

BEGIN;

SET LOCAL terminal.reason = 'Плохо поработал';

DELETE FROM employees_view 
WHERE employee_id = 92;

COMMIT;

-- Проверяем, остался ли сотрудник в employees
SELECT * FROM "Employees" 
WHERE employee_id = 92;

-- Смотрим причину увольнения
SELECT * FROM "FormerEmployees";




-- 2

SELECT * FROM "WarehouseStatus" ws 
WHERE product_id = 1233;
SELECT * FROM "Warehouse" w
WHERE product_id = 1233;


-- При удалении строки в Deliveries, делаем запись в Warehouse
CREATE OR REPLACE FUNCTION update_warehouse_after_delivery_delete()
RETURNS TRIGGER AS $$
DECLARE
    current_quantity INTEGER;
	warehouse_type TEXT;
BEGIN
    -- Получаем текущее количество товара из представления
    SELECT "Quantity_in_stock" INTO current_quantity
    FROM "WarehouseStatus"
    WHERE "product_id" = OLD."product_id"
    LIMIT 1;
    

    -- Рассчитываем новое количество
    current_quantity := COALESCE(current_quantity, 0) - OLD."Quantity";


	-- Проверка на отрицательное количество (защита от ошибок)
    IF current_quantity < 0 THEN
        RAISE WARNING 'Отрицательное количество товара % после удаления поставки. Установлено 0.', OLD."product_id";
        current_quantity := 0;
    END IF;
    
	-- Ищем тип склада, который был у продукта из поставки
	SELECT "Warehouse_type" FROM "WarehouseStatus"
	WHERE "product_id" = OLD."product_id"
	LIMIT 1 
	INTO warehouse_type;

	warehouse_type := COALESCE(warehouse_type, 'Основной');

    -- Создаем новую запись или обновляем существующую
    INSERT INTO "Warehouse" (
        "product_id",
        "Quantity_in_stock",
        "Date",
        "Warehouse_type"
    ) VALUES (
        OLD."product_id",
        current_quantity,
        CURRENT_DATE,
        warehouse_type
    );
    
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
    
-- AFTER триггер
CREATE OR REPLACE TRIGGER after_delivery_delete_stock
AFTER DELETE ON "Deliveries"
FOR EACH ROW
EXECUTE FUNCTION update_warehouse_after_delivery_delete();

-- Тест
-- Ищем тестовый продукт
SELECT * FROM "WarehouseStatus" ws 
WHERE product_id = 1233;

SELECT * FROM "Deliveries" d 
WHERE product_id = 1233;

-- Удаляем
DELETE FROM "Deliveries"
WHERE consignment_note_id = 16263;

-- Проверяем, что поставки больше нет
SELECT * FROM "Deliveries" d 
WHERE product_id = 1233;

-- Проверяем, что теперь на складе меньшее количество
SELECT * FROM "WarehouseStatus" ws 
WHERE product_id = 1233;



-- 3
-- Предупреждает об удалении поставки, которой меньше 7 дней
CREATE OR REPLACE FUNCTION warn_delivery_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- BEFORE-логика
    IF OLD."Arrival_date" > CURRENT_DATE - INTERVAL '7 days' THEN
        RAISE WARNING 'Удаляется свежая поставка (ID: %)', OLD."consignment_note_id";
    END IF;
	
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER before_delivery_delete_warner
BEFORE DELETE ON "Deliveries"
FOR EACH ROW
EXECUTE FUNCTION warn_delivery_deletion();

INSERT INTO "Deliveries"(consignment_note_id, "Arrival_date", supplier_id, product_id, "Quantity", "Expiration_date") VALUES
(999990, '2025-05-20', 1, 1, 100, '2025-06-10');

SELECT * FROM "Deliveries" d
WHERE "Arrival_date" = '2025-05-20';

DELETE FROM "Deliveries"
WHERE consignment_note_id = 999990;
