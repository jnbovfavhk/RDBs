create table "Constants" (
constant_text_description TEXT,
constant_value INTEGER
);

insert into "Constants" values (
'Наименьший срок годности товара в поставке исекает через', 3
);

insert into "Constants"(constant_text_description, constant_value) values 
('Наименьшая сумма чеков для уровня скидок 3', 50000),
('Наименьшая сумма чеков для уровня скидок 2', 20000),
('Наименьшее количество чеков для уровня скидок 1', 3);

insert into "Constants"(constant_text_description, constant_value) values 
('Телефон клиента должен начинаться с', 7),
('Телефон клиента должен иметь длину', 11);

insert into "Constants"(constant_text_description, constant_value) values 
('На сколько меняется опыт сотрудника при изменении его должности', 1);



select * from "Constants";
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
	min_expiry_days INTEGER;
BEGIN

	SELECT constant_value FROM "Constants"
	WHERE constant_text_description = 'Наименьший срок годности товара в поставке исекает через'
	INTO min_expiry_days;


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
    FROM "Warehouse"
    WHERE "product_id" = NEW."product_id"
    ORDER BY "Date" DESC
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
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- INSTEAD OF триггер для INSERT в представление
CREATE or replace TRIGGER instead_of_insert_delivery
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
SELECT * FROM "Warehouse" WHERE "product_id" = 8;

SELECT * FROM "WarehouseStatus" WHERE "product_id" = 8;

-- Вставляем новую поставку
INSERT INTO "DeliveriesView" (
    "consignment_note_id",
    "Arrival_date",
    "supplier_id",
    "product_id",
    "Quantity",
    "Expiration_date"
) VALUES (
    2461293,
    CURRENT_DATE,
    3,
    8,
    15,
    CURRENT_DATE + 30  -- Нормальный срок
);

-- Проверяем обновленное количество на складе
SELECT * FROM "WarehouseStatus" WHERE "product_id" = 8; 




-- 2
-- Функция для обновления уровня скидки клиента при добавлении продажи

CREATE OR REPLACE FUNCTION public.update_client_discount_on_receipt_change()
RETURNS trigger AS $$
DECLARE
    client_id_var INTEGER;
    current_discount SMALLINT;
    total_orders_var INTEGER;
    total_spent_var NUMERIC;

	discont_3_border_total_spent INTEGER;
	discont_2_border_total_spent INTEGER;
	discont_1_border_total_orders INTEGER;

BEGIN

	-- Определяем переменные
	SELECT constant_value FROM "Constants"
	WHERE constant_text_description = 'Наименьшая сумма чеков для уровня скидок 3'
	INTO discont_3_border_total_spent;

	SELECT constant_value FROM "Constants"
	WHERE constant_text_description = 'Наименьшая сумма чеков для уровня скидок 2'
	INTO discont_2_border_total_spent;

	SELECT constant_value FROM "Constants"
	WHERE constant_text_description = 'Наименьшее количество чеков для уровня скидок 1'
	INTO discont_1_border_total_orders;


	
    -- Определяем client_id в зависимости от операции
    IF TG_OP = 'DELETE' THEN
        client_id_var := OLD."client_id";
    ELSE
        client_id_var := NEW."client_id";
    END IF;
    
    -- Если чек без клиента, выходим
    IF client_id_var IS NULL THEN
        RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
    END IF;
    
    -- Пересчитываем общее количество заказов и сумму
    SELECT 
        COUNT(r."receipt_id"),
        COALESCE(SUM(r."Receipt_amount"), 0)
    INTO total_orders_var, total_spent_var
    FROM "Receipts" r
    WHERE r."client_id" = client_id_var;
    
    -- Логика расчета скидки
    IF total_spent_var >= discont_3_border_total_spent THEN
        current_discount := 3;
    ELSIF total_spent_var >= discont_2_border_total_spent THEN
        current_discount := 2;
    ELSIF total_orders_var >= discont_1_border_total_orders THEN
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
CREATE OR REPLACE TRIGGER check_client_discount_on_receipt_change
AFTER INSERT OR DELETE OR UPDATE ON "Receipts"
FOR EACH ROW EXECUTE FUNCTION update_client_discount_on_receipt_change();




INSERT INTO "Clients" (client_id, "Discount_level", "Card_number", "Phone_number") VALUES 
(9999962, 0, 1245456733443752, 79351993754);

SELECT * FROM "Clients" 
WHERE client_id = 9999962;

INSERT INTO "Receipts"("Date", "Time", client_id, "Receipt_amount", "Payment_type") VALUES
(CURRENT_DATE, CURRENT_TIME, 9999962, 1200, 'Карта'),
(CURRENT_DATE, CURRENT_TIME, 9999962, 1200, 'Карта'),
(CURRENT_DATE, CURRENT_TIME, 9999962, 1200, 'Карта'),
(CURRENT_DATE, CURRENT_TIME, 9999962, 1200, 'Карта');



select * from "Receipts" c 
where c.client_id = 9999962;

-- Проверка уровня скидок(должен быть 1 так как количество чеков >3)
SELECT * FROM "Clients" 
WHERE client_id = 9999962;



INSERT INTO "Receipts"("Date", "Time", client_id, "Receipt_amount", "Payment_type") VALUES
(CURRENT_DATE, CURRENT_TIME, 9999962, 20000, 'Карта');

-- Должен быть 2 потому что сумма чеков >20000 
SELECT * FROM "Clients" 
WHERE client_id = 9999962;

INSERT INTO "Receipts"("Date", "Time", client_id, "Receipt_amount", "Payment_type") VALUES
(CURRENT_DATE, CURRENT_TIME, 9999962, 30000, 'Наличные');

-- Должен быть 3
SELECT * FROM "Clients" 
WHERE client_id = 9999962;


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
DECLARE 
	phone_start_with INTEGER;
	phone_length INTEGER;
BEGIN
    
	SELECT constant_value FROM "Constants" 
	WHERE constant_text_description = 'Телефон клиента должен начинаться с'
	INTO phone_start_with;

	SELECT constant_value FROM "Constants" 
	WHERE constant_text_description = 'Телефон клиента должен иметь длину'
	INTO phone_length;
	
	-- Проверяем, изменились ли интересующие нас поля
    -- Для операции INSERT всегда проверяем
    IF TG_OP = 'INSERT' OR 
       (TG_OP = 'UPDATE' AND (
           (NEW."Phone_number" IS DISTINCT FROM OLD."Phone_number") OR
           (NEW."Card_number" IS DISTINCT FROM OLD."Card_number")
       )) THEN

	    IF NEW."Phone_number" IS NOT NULL THEN
	        -- Проверка, что номер начинается с 7 и имеет 11 цифр
	        IF NOT (NEW."Phone_number" >= phone_start_with * POWER(10, phone_length - 1) 
				AND (NEW."Phone_number" <= phone_start_with * POWER(10, phone_length - 1) + (POWER(10, phone_length - 1) - 1))) THEN
	            RAISE EXCEPTION 'Некорректный номер телефона. Номер должен начинаться с % и содержать % цифр', phone_start_with, phone_length;
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
UPDATE "Clients" SET "Card_number" = 456723469586309143
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
CREATE OR replace TRIGGER sales_change_trigger
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
DECLARE 
	change_year INTEGER;
BEGIN

	SELECT constant_value FROM "Constants"
	WHERE constant_text_description = 'На сколько меняется опыт сотрудника при изменении его должности'
	INTO change_year;

    -- Если должность изменилась И новый опыт не указан (равен старому)
    IF NEW."Position" IS DISTINCT FROM OLD."Position" AND 
       NEW."Experience" = OLD."Experience" THEN
        -- Увеличиваем опыт на 1 год
        NEW."Experience" := OLD."Experience" + change_year;
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
WHERE employee_id = 25;

-- Меняем должность
UPDATE employees_view 
SET "Position" = 'Директор'
WHERE employee_id = 25;

-- Опыт увеличился на 1
SELECT * FROM employees_view
WHERE employee_id = 25;


create table "Text_constants" (
description TEXT,
value TEXT
);

insert into "Text_constants" values
('Уведомлять при поступлении поставки моложе', '7 days');

insert into "Text_constants" values
('Причина увольнения сотрудника по умолчанию', 'По собственному желанию');

-- для DELETE
-- 1 Вместо удаления сотрудников из Employees будем изменять у них поле hiring
-- Изменяем исходную таблицу
alter table "Employees"
add column hiring BOOLEAN;

alter table "Employees"
add column termination_reason TEXT;

update "Employees" 
set hiring = true;


SELECT value FROM "Text_constants"
WHERE description = 'Причина увольнения сотрудника по умолчанию'
LIMIT 1;


-- Представление
CREATE OR REPLACE VIEW employees_view AS
SELECT * FROM "Employees";

-- Функция
CREATE OR REPLACE FUNCTION archive_employee_instead()
RETURNS TRIGGER AS $$
DECLARE
	termination_reason_var TEXT;
    termination_reason_default TEXT;
BEGIN
	SELECT value FROM "Text_constants"
	WHERE description = 'Причина увольнения сотрудника по умолчанию'
	LIMIT 1
	INTO termination_reason_default;

	BEGIN
        termination_reason_var := current_setting('terminal.reason');
    EXCEPTION WHEN undefined_object THEN
        termination_reason_var := termination_reason_default; -- По умолчанию
    END;

	
    UPDATE "Employees"
	SET hiring = FALSE,
		termination_reason = termination_reason_var
	WHERE employee_id = OLD.employee_id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- INSTEAD OF DELETE триггер
CREATE OR REPLACE TRIGGER archive_employee_instead_of_delete
INSTEAD OF DELETE ON employees_view
FOR EACH ROW
EXECUTE FUNCTION archive_employee_instead();

-- Тест
SELECT * FROM employees_view 
WHERE employee_id = 48;

DELETE FROM employees_view WHERE "employee_id" = 48;

-- Проверяем, что в таблице hiring теперь false и есть причина увольнения
SELECT * FROM employees_view 
where employee_id = 48;


-- Увольняем по другой причине
SELECT * FROM "Employees" 
WHERE employee_id = 94;

BEGIN;

SET LOCAL terminal.reason = 'Плохо поработал';

DELETE FROM employees_view 
WHERE employee_id = 94;

COMMIT;

-- Проверяем, остался ли сотрудник в employees
SELECT * FROM "Employees" 
WHERE employee_id = 94;





-- 2

SELECT * FROM "WarehouseStatus" ws 
WHERE product_id = 1257;
SELECT * FROM "Warehouse" w
WHERE product_id = 1257;


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
		DECLARE
			product_name TEXT;
		BEGIN
			SELECT "Product_name" FROM "Products" 
			WHERE product_id = OLD.product_id 
			INTO product_name;

	        RAISE WARNING 'Отрицательное количество товара % после удаления поставки. Установлено 0.', product_name;
	        current_quantity := 0;
		END;
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
WHERE product_id = 1257;

SELECT * FROM "Deliveries" d 
WHERE product_id = 1257;

-- Удаляем
DELETE FROM "Deliveries"
WHERE consignment_note_id = 88646;

-- Проверяем, что поставки больше нет
SELECT * FROM "Deliveries" d 
WHERE product_id = 1257;

-- Проверяем, что теперь на складе меньшее количество
SELECT * FROM "WarehouseStatus" ws 
WHERE product_id = 1257;



-- 3

-- Предупреждает об удалении поставки, которой меньше 7 дней
CREATE OR REPLACE FUNCTION warn_delivery_deletion()
RETURNS TRIGGER AS $$
DECLARE 
	notification TEXT;
BEGIN

	SELECT value FROM "Text_constants"
	WHERE description = 'Уведомлять при поступлении поставки моложе'
	into notification;

    -- BEFORE-логика
    IF OLD."Arrival_date" > CURRENT_DATE - notification::INTERVAL THEN
        RAISE WARNING 'Удаляется свежая поставка (ID накладной: %, прибыла: %, прошло дней: %)', 
                      OLD."consignment_note_id", 
                      OLD."Arrival_date", 
                      (CURRENT_DATE - OLD."Arrival_date");
    END IF;
	
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- BEFORE триггер
CREATE OR REPLACE TRIGGER before_delivery_delete_warner
BEFORE DELETE ON "Deliveries"
FOR EACH ROW
EXECUTE FUNCTION warn_delivery_deletion();

-- Тест
INSERT INTO "Deliveries"(consignment_note_id, "Arrival_date", supplier_id, product_id, "Quantity", "Expiration_date") VALUES
(999990, CURRENT_DATE, 1, 1, 100, '2025-06-10');


SELECT * FROM "Deliveries" d
WHERE "Arrival_date" = CURRENT_DATE;

DELETE FROM "Deliveries"
WHERE consignment_note_id = 999990;
