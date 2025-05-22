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

-- Функция для счета зарплаты сотрудникам, включая бонусы
CREATE OR REPLACE FUNCTION calculate_salary_with_bonuses(
    search_month INTEGER,
    search_year INTEGER
)
RETURNS TABLE (
    employee_id INTEGER,
    full_name TEXT,
    job_position TEXT,
    base_salary NUMERIC(10,2),
    bonus NUMERIC(10,2),
    total_salary NUMERIC(10,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH 
    -- Считаем блюда поваров за период и добавляем каждому к зп по 15 руб за одно
    cook_stats AS (
        SELECT 
            s."cook_id" AS employee_id,
            COUNT(*) * 15 AS bonus_value
        FROM "Sales" s
        JOIN "Receipts" r ON s."receipt_id" = r."receipt_id"
        WHERE EXTRACT(MONTH FROM r."Date") = search_month
        AND EXTRACT(YEAR FROM r."Date") = search_year
        GROUP BY s."cook_id"
    ),
    -- Считаем чеки официантов за период и добавляем по 10 руб за каждый
    waiter_stats AS (
        SELECT 
            r."waiter_id" AS employee_id,
            COUNT(*) * 10 AS bonus_value
        FROM "Receipts" r
        WHERE EXTRACT(MONTH FROM r."Date") = search_month
        AND EXTRACT(YEAR FROM r."Date") = search_year
        GROUP BY r."waiter_id"
    )
    SELECT 
        e."employee_id",
        e."Full_name",
        e."Position",
        e."Salary"::NUMERIC(10,2),
        COALESCE(
            CASE
                WHEN e."Position" = 'Повар' THEN cs.bonus_value
                WHEN e."Position" = 'Официант' THEN ws.bonus_value
                ELSE 0
            END, 0
        )::NUMERIC(10,2) AS bonus,
        e."Salary"::NUMERIC(10,2) + COALESCE(
            CASE
                WHEN e."Position" = 'Повар' THEN cs.bonus_value
                WHEN e."Position" = 'Официант' THEN ws.bonus_value
                ELSE 0
            END, 0
        )::NUMERIC(10,2) AS total_salary
    FROM 
        "Employees" e
    LEFT JOIN cook_stats cs ON e."employee_id" = cs.employee_id AND e."Position" = 'Повар'
    LEFT JOIN waiter_stats ws ON e."employee_id" = ws.employee_id AND e."Position" = 'Официант'
    ORDER BY 
        e."Full_name";
END;
$$ LANGUAGE plpgsql;

-- Процедура для этого
CREATE OR REPLACE PROCEDURE get_employee_salaries_with_bonuses(
    IN p_month INTEGER,
    IN p_year INTEGER,
    INOUT result_cursor REFCURSOR DEFAULT 'salaries_cursor'
)
AS $$
BEGIN
    OPEN result_cursor FOR
    SELECT * FROM calculate_salary_with_bonuses(p_month, p_year);
END;
$$ LANGUAGE plpgsql;

-- Проверка функции
SELECT * FROM calculate_salary_with_bonuses(6, 2023);

-- Проверка процедуры
CALL get_employee_salaries_with_bonuses(6, 2023);
FETCH ALL FROM salaries_cursor;
