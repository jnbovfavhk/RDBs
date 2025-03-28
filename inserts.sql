
INSERT INTO "Dishes" ("Name", "Calories", "Type", "Price") VALUES
('Салат Цезарь', 200, 'Салат', 400),
('Пицца Маргарита', 300, 'Основное блюдо', 500),
('Тирамису', 400, 'Десерт', 600);


INSERT INTO "Suppliers" ("Name") VALUES
('Зеленая долина'),
('Здоровое питание');





INSERT INTO "Employees" ("Position", "Full_name", "Experience", "Phone_number") VALUES
('Официант', 'Иван Иванов', 2, 89001234567),
('Повар', 'Петр Петров', 5, 89007654321);





INSERT INTO "Allergens" ("Allergen") VALUES
('Глютен'),
('Орехи'),
('Лактоза');





INSERT INTO "Clients" ("Discount_level", "Card_number", "Phone_number") VALUES
(1, 1234567890123456, 89005551234),
(2, 1234567890123457, 89005551235);


INSERT INTO "Products" ("Product_name") VALUES
('Курица'),
('Помидоры'),
('Сыр');

INSERT INTO "Warehouse" ("product_id", "Quantity_in_stock", "Date", "Warehouse_type") VALUES
(1, 100, '2023-10-01', 'Холодный склад'),
(2, 50, '2023-10-01', 'Холодный склад'),
(3, 200, '2023-10-01', 'Сухой склад');

INSERT INTO "Dishes_and_Ingredients" ("product_id", "Product_quantity", "dish_id", "Cooking_method") VALUES
(1, 50, 1, 'Смешать'),
(2, 100, 2, 'Выпекать'),
(3, 30, 3, 'Собрать');

INSERT INTO "Deliveries" ("consignment_note_id", "Arrival_date", "supplier_id", "product_id", "Quantity", "Expiration_date") VALUES
(1001, '2023-10-05', 1, 1, 50, '2023-12-01'),
(1002, '2023-10-06', 2, 2, 30, '2023-11-15');

INSERT INTO "Receipts" ("Date", "Time", "waiter_id", "Receipt_amount", "client_id", "Payment_type") VALUES
('2023-10-07', '12:30:00', 1, 1000, 1, 'Наличные'),
('2023-10-07', '13:00:00', 2, 1500, 2, 'Карта');

INSERT INTO "Sales" ("dish_id", "cook_id", "receipt_id", "Sale_amount") VALUES
(1, 2, 1, 400),
(2, 2, 2, 500);

INSERT INTO "Allergens_and_products" (allergen_id, product_id) VALUES
(1, 1),
(2, 2);
