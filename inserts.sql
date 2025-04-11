
INSERT INTO "Dishes" ("Name", "Calories", "Type", "Price") VALUES
('Салат Цезарь', 200, 'Салат', 400),
('Пицца Маргарита', 300, 'Основное блюдо', 500),
('Тирамису', 400, 'Десерт', 600);


INSERT INTO "Suppliers" ("Name") VALUES
('Зеленая долина'),
('Здоровое питание');


INSERT into "Dishes" ("Name", "Calories", "Price") values
('Мекисканская пицца', 600, 900),
('    Клубника   ', 100, 300),
('Вегетарианский бургер', 200, 600),
('Крем-суп вегетарианский', 400, 650);

insert into "Products" ("Product_name") values
('Клубника');


INSERT INTO "Employees" ("Position", "Full_name", "Experience", "Phone_number") VALUES
('Официант', 'Иван Иванов', 2, 89001234567),
('Повар', 'Петр Петров', 5, 89007654321);

INSERT INTO "Employees" ("Position", "Full_name", "Experience", "Phone_number", "Salary") VALUES
('Повар', 'Иван Поваров', 5, 89007654321, 70000);



INSERT INTO "Allergens" ("Allergen") VALUES
('Глютен'),
('Орехи'),
('Лактоза');





INSERT INTO "Clients" ("Discount_level", "Card_number", "Phone_number") VALUES
(1, 1234567890123456, 89005551234),
(2, 1234567890123457, 89005551235);

INSERT INTO "Clients" ("Discount_level", "Card_number", "Phone_number") VALUES
(3, 6789456734561234, 89035551284);

INSERT INTO "Clients" ("Card_number", "Phone_number") VALUES
(1234567891223406, 89080551234);

insert into "Suppliers" ("Name") values
('ООО Картинный'),
('ИП Карандашов А.Б.');

insert into "Deliveries" ("Arrival_date", consignment_note_id, supplier_id, product_id, "Expiration_date") values
('2025-09-01', 19803, 3, 3, '2025-12-01');


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
('2023-10-07', '13:40:00', 2, 1500, 2, 'Карта')
('2023-10-08', '13:30:00', 2, 3200, 2, 'Карта')
('2023-10-08', '13:00:00', 2, 1500, 2, 'Карта')
('2023-10-10', '13:10:00', 2, 1000, 2, 'Карта')
('2023-10-15', '13:10:00', 2, 800, 2, 'Карта')
('2023-10-15', '13:47:00', 2, 900, 2, 'Карта')
('2023-10-15', '13:09:00', 2, 1500, 2, 'Карта');

INSERT INTO "Receipts" ("Date", "Time", "waiter_id", "Receipt_amount", "client_id", "Payment_type") values
('2023-11-23', '12:09:00', 1, 900, 1, 'Наличные'),
('2023-09-23', '21:09:00', 3, 2000, 1, 'Наличные'),
('2023-08-01', '16:00:00', 2, 1300, 1, 'Наличные'),
('2023-08-02', '17:00:00', 3, 900, 1, 'Наличные'),
('2023-05-05', '15:40:00', 1, 2300, 1, 'Карта'),
('2023-05-06', '15:42:00', 1, 2300, 1, 'Карта');


INSERT INTO "Receipts" ("Date", "Time", "waiter_id", "Receipt_amount", "client_id", "Payment_type") VALUES
('2025-04-11', '9:30:00', 1, 1000, 1, 'Наличные'),
('2023-04-11', '9:00:00', 2, 1500, 2, 'Карта');

INSERT INTO "Sales" ("dish_id", "cook_id", "receipt_id", "Sale_amount") VALUES
(1, 2, 1, 400),
(2, 2, 2, 500);

INSERT INTO "Allergens_and_dishes" (allergen_id, dish_id) VALUES
(1, 1),
(2, 2);
