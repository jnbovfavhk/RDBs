CREATE VIEW "MenuWithAllergens" AS
SELECT 
    d."dish_id",
    d."Name" AS "Dish_name",
    d."Calories",
    d."Type",
    d."Price",
    STRING_AGG(a."Allergen", ', ') AS "Allergens"
FROM 
    "Dishes" d
LEFT JOIN 
    "Allergens_and_dishes" ad ON d."dish_id" = ad."dish_id"
LEFT JOIN 
    "Allergens" a ON ad."allergen_id" = a."allergen_id"
GROUP BY 
    d."dish_id";



CREATE VIEW "PopularDishes" AS
SELECT 
    d."dish_id",
    d."Name" AS "Dish_name",
    COUNT(s."sale_id") AS "Sales_count",
    SUM(s."Sale_amount") AS "Total_income"
FROM 
    "Dishes" d
JOIN 
    "Sales" s ON d."dish_id" = s."dish_id"
GROUP BY 
    d."dish_id"
ORDER BY 
    "Sales_count" DESC
LIMIT 50;


CREATE VIEW "WarehouseStatus" AS
SELECT DISTINCT ON (w."product_id")
    w."product_id",
    p."Product_name",
    w."Quantity_in_stock",
    w."Date",
    w."Warehouse_type"
FROM 
    "Warehouse" w
JOIN 
    "Products" p ON w."product_id" = p."product_id"
ORDER BY 
    w."product_id", w."Date" DESC;


-- Задача 2
-- Базовое представление с фильтром по цене
CREATE VIEW "ExpensiveDishes" AS
SELECT 
    "dish_id",
    "Name",
    "Calories",
    "Type",
    "Price"
FROM 
    "Dishes"
WHERE 
    "Price" > 1000;


-- Представление, расширяющее базовое с LOCAL CHECK
CREATE VIEW "ExpensiveVegetarianDishes_Local" AS
SELECT * FROM "ExpensiveDishes"
WHERE "Type" = 'Основное'
WITH LOCAL CHECK OPTION;

-- Представление, расширяющее базовое с CASCADED CHECK
CREATE VIEW "ExpensiveVegetarianDishes_Cascaded" AS
SELECT * FROM "ExpensiveDishes"
WHERE "Type" = 'Основное'
WITH CASCADED CHECK OPTION;


-- Тестовые запросы
-- Этот не вызывает ошибку, потому что в базовом представлении нет with check option и потому что имеется опция local
INSERT INTO "ExpensiveVegetarianDishes_Local" ("Name", "Calories", "Type", "Price")
VALUES ('Каша манная', 800, 'Основное', 900);

-- Этот вызывает ошибку, потому что опция cascade, которая проверяет все условия
INSERT INTO "ExpensiveVegetarianDishes_Cascaded" ("Name", "Calories", "Type", "Price")
VALUES ('Каша манная', 800, 'Основное', 900);


-- Задача 3
CREATE MATERIALIZED VIEW "MaterializedPopularDishes" AS
SELECT 
    d."dish_id",
    d."Name" AS "Dish_name",
    COUNT(s."sale_id") AS "Sales_count",
    SUM(s."Sale_amount") AS "Total_revenue"
FROM 
    "Dishes" d
JOIN 
    "Sales" s ON d."dish_id" = s."dish_id"
GROUP BY 
    d."dish_id";


CREATE INDEX "idx_mv_popular_dishes_sales" 
ON "MaterializedPopularDishes" ("Sales_count" DESC);


-- Тест
SELECT * FROM "MaterializedPopularDishes"
ORDER BY "Sales_count" DESC;


SELECT 
    d."dish_id",
    d."Name" AS "Dish_name",
    COUNT(s."sale_id") AS "Sales_count",
    SUM(s."Sale_amount") AS "Total_revenue"
FROM "Dishes" d
JOIN "Sales" s ON d."dish_id" = s."dish_id"
GROUP BY d."dish_id"
ORDER BY "Sales_count";
