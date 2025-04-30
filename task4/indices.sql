
-- простые 
CREATE INDEX idx_dishes_calories ON "Dishes" ("Calories");
CREATE INDEX idx_dishes_price ON "Dishes" ("Price");


--уникальный b tree
CREATE UNIQUE INDEX idx_clients_card_unique ON "Clients" ("Card_number") 
WHERE "Card_number" IS NOT NULL;


-- частичный hash
CREATE INDEX idx_cheap_dishes_hash ON "Dishes" USING HASH ("Name")
WHERE "Price" < 1000;

--hash с использованием выражений 
CREATE INDEX idx_deliveries_day_hash ON "Deliveries" USING HASH (DATE("Arrival_date"));

-- простой using hash
CREATE INDEX idx_dishes_type_hash ON "Dishes" USING HASH ("Type");

-- составной
CREATE INDEX idx_warehouse_product_date ON "Warehouse" ("product_id", "Date" DESC);


-- покрывающий
CREATE INDEX idx_covering_receipts_extended ON "Receipts" 
(
    DATE_PART('year', "Date"),
    DATE_PART('month', "Date")
)
INCLUDE (receipt_id, "Receipt_amount", "waiter_id", "Date", "Time", client_id, "Payment_type");

--частичный
CREATE INDEX idx_employees_chefs_waiters ON "Employees" (employee_id)
WHERE "Position" IN ('Официант', 'Повар');

-- частичный покрывающий
CREATE INDEX idx_employees_chefs_waiters_covering ON "Employees" (employee_id)
INCLUDE ("Full_name", "Phone_number", "Salary", "Position", "Experience", employee_id)
WHERE "Position" IN ('Официант', 'Повар');

-- с использованием выражений
CREATE INDEX idx_receipts_month_year ON "Receipts" 
(EXTRACT(MONTH FROM "Date"), EXTRACT(YEAR FROM "Date"));
