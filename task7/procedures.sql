-- Функция для расчета прибыли за каждый день в заданном периоде
CREATE OR REPLACE FUNCTION calculate_daily_profit(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    day_date DATE,
    daily_profit NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r."Date" AS day_date,
        SUM(r."Receipt_amount")::NUMERIC AS daily_profit
    FROM 
        "Receipts" r
    WHERE 
        r."Date" BETWEEN start_date AND end_date
    GROUP BY 
        r."Date"
    ORDER BY 
        r."Date";
END;
$$ LANGUAGE plpgsql;

-- Фунция для расчета прибыли а каждый месяц в заданном периоде
CREATE OR REPLACE FUNCTION calculate_monthly_profit(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    year_num INTEGER,
    month_num INTEGER,
    monthly_profit NUMERIC(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(YEAR FROM r."Date")::INTEGER AS year_num,
        EXTRACT(MONTH FROM r."Date")::INTEGER AS month_num,
        CAST(SUM(r."Receipt_amount") AS NUMERIC(10,2)) AS monthly_profit
    FROM 
        "Receipts" r
    WHERE 
        r."Date" BETWEEN start_date AND end_date
    GROUP BY 
        EXTRACT(YEAR FROM r."Date"), EXTRACT(MONTH FROM r."Date")
    ORDER BY 
        year_num, month_num;
END;
$$ LANGUAGE plpgsql;


-- Функция для проверки аллергенов в блюде по названию блюда
CREATE OR REPLACE FUNCTION check_allergens_by_dish_name(
    dish_name TEXT
)
RETURNS SETOF TEXT AS $$
DECLARE
    dish_id_var INTEGER;
BEGIN
    -- Находим ID блюда по имени
    SELECT d."dish_id" INTO dish_id_var
    FROM "Dishes" d
    WHERE d."Name" ILIKE dish_name;
    
    IF dish_id_var IS NULL THEN
        RETURN NEXT 'Блюдо не найдено';
        RETURN;
    END IF;
    
    -- Возвращаем аллергены для найденного блюда
    RETURN QUERY
    SELECT a."Allergen"::TEXT
    FROM "Allergens" a
    JOIN "Allergens_and_dishes" ad ON a."allergen_id" = ad."allergen_id"
    WHERE ad."dish_id" = dish_id_var;
    
    IF NOT FOUND THEN
        RETURN NEXT 'Аллергены не обнаружены';
    END IF;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM calculate_daily_profit('2023-01-01', '2023-01-31');

SELECT * FROM calculate_monthly_profit('2023-01-01', '2023-12-31');

SELECT * FROM check_allergens_by_dish_name('Салат Цезарь');


-- Процедуры
INSERT INTO "Constants" VALUES 
('Бонус сотрудникам за каждое приготовленное ими блюдо', 20),
('Бонус сотрудникам за каждый отпущенный чек', 15);

-- Функция для счета зарплаты сотрудникам, включая бонусы
CREATE OR REPLACE FUNCTION calculate_salary_with_bonuses(
    month INTEGER,
    year INTEGER
) RETURNS TABLE (
    employee_id INTEGER,
    full_name TEXT,
    job_position TEXT,
    base_salary NUMERIC(10,2),
    dishes_bonus NUMERIC(10,2),
    receipts_bonus NUMERIC(10,2),
    total_bonus NUMERIC(10,2),
    total_salary NUMERIC(10,2)
) AS $$
DECLARE
    dish_bonus_rate NUMERIC(10,2);
    receipt_bonus_rate NUMERIC(10,2);
BEGIN
    -- Получаем ставки бонусов
    SELECT constant_value::NUMERIC(10,2) INTO dish_bonus_rate
    FROM "Constants"
    WHERE constant_text_description = 'Бонус сотрудникам за каждое приготовленное ими блюдо';
    
    SELECT constant_value::NUMERIC(10,2) INTO receipt_bonus_rate
    FROM "Constants"
    WHERE constant_text_description = 'Бонус сотрудникам за каждый отпущенный чек';
    
    RETURN QUERY
    SELECT 
        e.employee_id,
        e."Full_name",
        e."Position",
        e."Salary"::NUMERIC(10,2) AS base_salary,
        
        -- Бонус за блюда
        COALESCE(dish_bonuses.dishes_count * dish_bonus_rate, 0) AS dishes_bonus,
        
        -- Бонус за чеки
        COALESCE(receipt_bonuses.receipts_count * receipt_bonus_rate, 0) AS receipts_bonus,
        
        -- Общий бонус
        COALESCE(dish_bonuses.dishes_count * dish_bonus_rate, 0) + COALESCE(receipt_bonuses.receipts_count * receipt_bonus_rate, 0) AS total_bonus,
        
        -- Итоговая зарплата(основная плюс общий бонус)
        e."Salary"::NUMERIC(10,2) + 
        COALESCE(dish_bonuses.dishes_count * dish_bonus_rate, 0) + 
        COALESCE(receipt_bonuses.receipts_count * receipt_bonus_rate, 0) AS total_salary
    FROM "Employees" e

    LEFT JOIN (
		-- Подзапрос для подсчета количества приготовленных блюд 
        SELECT s.cook_id, COUNT(*) AS dishes_count
        FROM "Sales" s
        JOIN "Receipts" r ON s.receipt_id = r.receipt_id
        WHERE EXTRACT(MONTH FROM r."Date") = month
          AND EXTRACT(YEAR FROM r."Date") = year
        GROUP BY s.cook_id
    ) dish_bonuses ON dish_bonuses.cook_id = e.employee_id
    LEFT JOIN (
		-- Подзапрос для подсчета количества отпущенных чеков 
        SELECT 
            r.waiter_id,
            COUNT(*) AS receipts_count
        FROM "Receipts" r
        WHERE EXTRACT(MONTH FROM r."Date") = month
          AND EXTRACT(YEAR FROM r."Date") = year
        GROUP BY r.waiter_id
    ) receipt_bonuses ON receipt_bonuses.waiter_id = e.employee_id
    ORDER BY e."Full_name"; -- Сортируем по полному имени сотрудника
END;
$$ LANGUAGE plpgsql;


-- Обновленная процедура
CREATE OR REPLACE PROCEDURE get_salaries_with_bonuses(
    month INTEGER,
    year INTEGER,
    INOUT cur REFCURSOR = 'salaries_cursor'
) AS $$
BEGIN
    OPEN cur FOR SELECT * FROM calculate_salary_with_bonuses(month, year);
END;
$$ LANGUAGE plpgsql;

-- Проверка функции
SELECT * FROM calculate_salary_with_bonuses(6, 2023);

-- Проверка процедуры
BEGIN;
CALL get_employee_salaries_with_bonuses(6, 2023);
FETCH ALL FROM salaries_cursor;
COMMIT;


-- Выручка с каждого блюда за определенный период времени
CREATE OR REPLACE FUNCTION calculate_revenue_per_dish(
    start_date DATE,
    end_date DATE
) RETURNS TABLE (
    dish_name TEXT,
    total_revenue REAL  -- Общая выручка с блюда
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d."Name" AS dish_name,
        SUM(s."Sale_amount") AS total_revenue            -- Сумма всех продаж данного блюда
    FROM "Dishes" d
    JOIN "Sales" s ON d.dish_id = s.dish_id
    JOIN "Receipts" r ON s.receipt_id = r.receipt_id
    WHERE r."Date" BETWEEN start_date AND end_date
    GROUP BY d."Name"
    ORDER BY total_revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- Процедура
CREATE OR REPLACE PROCEDURE get_revenue_report(
    start_date DATE,
    end_date DATE,
    INOUT cur REFCURSOR = 'revenue_cursor'
) AS $$
BEGIN
    OPEN cur FOR SELECT * FROM calculate_revenue_per_dish(start_date, end_date);
END;
$$ LANGUAGE plpgsql;



SELECT * FROM calculate_revenue_per_dish('2023-01-01', '2023-12-31');

BEGIN;
CALL get_revenue_report('2023-01-01', '2023-12-01');
FETCH ALL FROM revenue_cursor;
COMMIT;

