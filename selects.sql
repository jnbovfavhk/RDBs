-- Получить блюда, их цены и поваров, которые их готовили
SELECT D."Name" AS Dish, D."Price", E."Full_name" AS Cook, R."Date" 
FROM "Dishes" D
INNER JOIN "Sales" S ON D.dish_id = S.dish_id
INNER JOIN "Receipts" R ON R.receipt_id = S.receipt_id
INNER JOIN "Employees" E ON S.cook_id = E.employee_id;

-- То же, но если данных о поваре или дате нет, то null
SELECT D."Name" AS Dish, D."Price", E."Full_name" AS Cook, R."Date" 
FROM "Dishes" D
LEFT JOIN "Sales" S ON D.dish_id = S.dish_id
LEFT JOIN "Receipts" R ON R.receipt_id = S.receipt_id
LEFT JOIN "Employees" E ON S.cook_id = E.employee_id;

-- Показывает чеки, продажи которых не были зарегистрированы
SELECT D."Name" AS Dish, S.sale_id, D."Price", R."Date", R."Time" 
FROM "Sales" S
LEFT JOIN "Dishes" D ON D.dish_id = S.dish_id 
RIGHT JOIN "Receipts" R ON R.receipt_id = S.receipt_id

-- Показывает декартово произведение клиентов и аллергенов(для возможной отметки всех аллергий клиентов)
SELECT C.*, A."Allergen"
FROM "Clients" c
CROSS JOIN "Allergens" A;

-- Перебрать всех возможных клиентов и их возможных 2-х аллергенов
SELECT C.*, Allergens.*
FROM "Clients" c
CROSS JOIN LATERAL (
	SELECT A."Allergen" AS "PossibleAllergen1", B."Allergen" AS "PossibleAllergen2"
	FROM "Allergens" A
	CROSS JOIN "Allergens" B
) Allergens;

-- Получить информацию о продажах + блюда, которые еще не были проданы + продажи блюд, которых больше нет
SELECT D."Name" AS Dish, S."Sale_amount"
FROM "Dishes" D
FULL JOIN "Sales" S ON D.dish_id = S.dish_id;


-- Блюда, их ингридиенты, количество интгридиента и что с ним сделать
SELECT D."Name" AS Dish, P."Product_name", DI."Product_quantity", DI."Cooking_method"
FROM "Dishes" D
JOIN "Dishes_and_Ingredients" DI ON D.dish_id = DI.dish_id
JOIN "Products" P ON DI.product_id = P.product_id;

-- Получить названия блюд, которые также являются продуктами
SELECT "Name" FROM "Dishes"
INTERSECT
SELECT "Product_name" FROM "Products";


-- Вывести официантов и поваров
SELECT E.*
FROM "Employees" E
WHERE E."Position" = 'Официант'
UNION 
SELECT E.*
FROM "Employees" E
WHERE E."Position" = 'Повар'

-- Получить все блюда, в которых калорий меньше 400 или цена меньше 400
SELECT D.* 
FROM "Dishes" D
WHERE D."Calories" < 400
UNION ALL
SELECT D.* 
FROM "Dishes" D
WHERE D."Price" < 400

-- Получить названия блюд, которые не являются продуктами
SELECT "Name" FROM "Dishes"
EXCEPT
SELECT "Product_name" FROM "Products";

-- Получить то, что на складе есть
SELECT P."Product_name", W."Quantity_in_stock"
FROM "Products" P
FULL JOIN "Warehouse" W ON P.product_id = W.product_id;

-- Получить всех клиентов, которые сделали хотя бы один заказ
SELECT C.*
FROM "Clients" C
WHERE EXISTS (
    SELECT 1 FROM "Receipts" R WHERE R.client_id = C.client_id
);


-- Получить блюда, в которых нет аллергена - орехов
SELECT D."Name" AS Dish
FROM "Dishes" D
WHERE NOT EXISTS (
    SELECT 1
    FROM "Allergens_and_dishes" AD
    JOIN "Allergens" A ON AD.allergen_id = A.allergen_id
    WHERE AD.dish_id = D.dish_id
    AND A."Allergen" = 'Орехи'
);

-- Получить клиентов с уровнем скидок 2 и 3
SELECT *
FROM "Clients"
WHERE "Discount_level" IN (2, 3);


-- Самое(ые) дорогое блюдо
SELECT "Name", "Price"
FROM "Dishes"
WHERE "Price" >= ALL (SELECT "Price" FROM "Dishes");

-- Показать работников, зарплата которых больше зарплаты хотя бы одного повара
SELECT E.*
FROM "Employees" E
WHERE E."Salary" >= SOME (SELECT E."Salary" FROM "Employees" E WHERE E."Position" = 'Повар')


-- Блюда, цена которых в диапазоне от 300 до 500
SELECT "Name"
FROM "Dishes"
WHERE "Price" BETWEEN 300 AND 500;


-- Выбрать все пиццы из блюд
SELECT *
FROM "Dishes"
WHERE "Name" ILIKE '%пицца%';

-- Вывести все ООО и ИП в поставщиках
SELECT "Name"
FROM "Suppliers"
WHERE "Name" SIMILAR TO '(ООО|ИП)%';

-- Заменить уровень клинента на категории и вывести
SELECT client_id, "Card_number", "Phone_number",
       CASE 
           WHEN "Discount_level" = 1 THEN 'Новый клиент'
           WHEN "Discount_level" = 2 THEN 'Регулярный'
           WHEN "Discount_level" = 3 THEN 'Постоянный клиент'
           ELSE 'Неизвестный уровень'
       END AS Discount_description
FROM "Clients";


-- Преобразование калорий типа int8 в текст 
SELECT dish_id, "Name", 
       CAST("Calories" AS TEXT) AS Calories_as_text
FROM "Dishes";


-- Преобразование дат и времен в текст
SELECT receipt_id, "Date"::TEXT, "Time"::Text
FROM "Receipts";


-- Получить все поставки, заменяя количество привезенного товара с null на 0
SELECT consignment_note_id, 
       COALESCE("Quantity", 0) AS Quantity_or_zero
FROM "Deliveries";


-- Получить чек с самой большой суммой заказа за сегодня
SELECT * 
FROM "Receipts" R
WHERE R."Receipt_amount" = ( 
select GREATEST(R."Receipt_amount")
from "Receipts" R
where R."Date" = CURRENT_DATE
);



-- Выбрать самую последнюю поставку среди нескольких
SELECT 
    GREATEST((SELECT MAX("Arrival_date") FROM "Deliveries" WHERE consignment_note_id = 1001),
              (SELECT MAX("Arrival_date") FROM "Deliveries" WHERE consignment_note_id = 1002),
              (SELECT MAX("Arrival_date") FROM "Deliveries" WHERE consignment_note_id = 1003)) AS latest_delivery_date;


-- Выбрать самую давнюю поставку среди нескольких постащиков
SELECT 
    LEAST((SELECT MAX("Arrival_date") FROM "Deliveries" WHERE supplier_id = 1),
              (SELECT MAX("Arrival_date") FROM "Deliveries" WHERE supplier_id = 2),
              (SELECT MAX("Arrival_date") FROM "Deliveries" WHERE supplier_id = 3)) AS latest_delivery_date;


-- Блюда с длинами их названий
SELECT "Name", LENGTH("Name") AS Name_Length
FROM "Dishes";


-- блюда с удаленными пробелами в начале и конце
SELECT "Name", BTRIM("Name") AS Trimmed_Name
FROM "Dishes";


-- Показать клиентов с их классами, соответствующими уровню скидок
SELECT 
    C.*,
    CHR(c."Discount_level" + 64) AS "Client_Class"
FROM 
    "Clients" C;

-- Возвращает блюда и ASCII код первого символа их названия
SELECT 
    d."Name",
    ASCII(SUBSTRING(d."Name" FROM 1 FOR 1)) AS first_character_ascii
FROM 
    "Dishes" d;


-- Только блюда, где в названии есть текст о том, что оно вегетарианское
SELECT 
    d."Name"
FROM "Dishes" d
WHERE 
    STRPOS(d."Name", 'Вегета') > 0
    OR 
    STRPOS(d."Name", 'вегета') > 0;


-- Заменить первые три символа в названии блюд на "Тест"
SELECT 
    d."Name",
    OVERLAY(d."Name" PLACING 'Тест' FROM 1 FOR 3) AS modified_name
FROM 
    "Dishes" d;

-- Сокращенные названия блюд
SELECT 
    d."Name",
    SUBSTRING(d."Name" FROM 1 FOR 7) AS short_name
FROM 
    "Dishes" d;

--Вывести всех клиентов, у которых номер телефона содержит 900
SELECT C.*
FROM "Clients" C
WHERE POSITION('900' IN C."Phone_number"::TEXT) > 0;


-- Замена имен
SELECT 
    d."Name",
    REPLACE(d."Name", 'Тирамису', 'Пышный тирамису по-венгерски') AS updated_name
FROM 
    "Dishes" d;


-- все названия поставщиков в нижнем регистре
SELECT 
    S."Name",
    LOWER(S."Name") AS name_lowercase
FROM 
    "Suppliers" S;

-- все названия поставщиков в верхнем регистре
SELECT 
    S."Name",
    UPPER(S."Name") AS name_lowercase
FROM 
    "Suppliers" S;



-- Все чеки, созданные сегодня
SELECT *
FROM "Receipts"
WHERE "Date" = CURRENT_DATE;




-- Все чеки, проданные в течение последнего часа
SELECT *
FROM "Receipts"
WHERE "Date" + "Time" >= NOW() - '1 hour'::interval;


-- Получение чеков за последнеий час по локальному времени
SELECT *
FROM "Receipts"
WHERE ("Date" + "Time") >= LOCALTIMESTAMP - '1 hour'::interval;


-- Все чеки за сегодня с 9 до 12 часов
SELECT *
FROM "Receipts" R
WHERE "Date" = CURRENT_DATE
AND "Time" BETWEEN '09:00:00' AND '12:00:00'


-- Все чеки до текущего момента
SELECT 
    receipt_id,
    "Date"
FROM 
    "Receipts"
WHERE 
    "Date" < CURRENT_TIMESTAMP;

-- Показать возраста всех чеков
SELECT *, AGE(NOW(), "Date" + "Time")
FROM "Receipts"

-- Количества чеков за каждый месяц 2023 года
SELECT DATE_PART('month', "Date") as Receipt_month,
	COUNT(receipt_id) AS total_receipts
FROM "Receipts"
WHERE DATE_PART('year', "Date") = DATE_PART('year', DATE('2023-01-01'))
GROUP BY Receipt_month
ORDER BY Receipt_month;




-- Получить чеки и их года
SELECT receipt_id, EXTRACT(YEAR FROM "Date") AS year, waiter_id, "Receipt_amount"
FROM "Receipts";



--Количество блюд в меню
SELECT COUNT(*) AS Total_Dishes
FROM "Dishes";


-- Суммы продаж за каждый день за 10-й месяц 2023 года
SELECT 
    "Date" AS ReceiptDate, 
    SUM("Receipt_amount") AS AverageAmount
FROM "Receipts"
WHERE 
    EXTRACT(MONTH FROM "Date") = 10 
    AND EXTRACT(YEAR FROM "Date") = 2023 
GROUP BY 
    DATE("Date")
ORDER BY 
    "Date";


-- Средняя зарплата всех должностей сотрудников
SELECT "Position", AVG("Salary") AS "AVG_salary"
FROM "Employees"
GROUP BY "Position";


-- Колиество чеков за каждый день 10 месяца 2023 года
SELECT 
    "Date" AS ReceiptDate, 
    COUNT(receipt_id) AS AverageAmount
FROM "Receipts"
WHERE 
    EXTRACT(MONTH FROM "Date") = 10 
    AND EXTRACT(YEAR FROM "Date") = 2023 
GROUP BY 
    DATE("Date")
ORDER BY 
    "Date";


-- Получить id клиентов, которые сделали больше 3-х заказов
SELECT C.client_id, COUNT(R.receipt_id) AS order_count
FROM "Clients" C
JOIN "Receipts" R ON C.client_id = R.client_id
GROUP BY C.client_id
HAVING COUNT(R.receipt_id) > 3;
