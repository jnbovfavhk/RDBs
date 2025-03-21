insert into "Suppliers" ("Name") 
values ('OOO "Волга"'), 
('ЗАО "Сибирское поле"');

insert into "Employees" ("Position", "Full_name", "Experience", "Phone_number")
values ('Официант', 'Иванов Сергей Игоревич', 0, +79675431232),
('Администратор', 'Дворецкий Алекстандр Демьянович', 3, +79028946765);


insert into "Dishes" ("Name", "Calories", "Type", "Price")
values ('Паста по-итальянски', 350, 'Вареное', 800),
('Чешское пиво', 400, null, 300);

insert into "Warehouse" ("product_id", "Quantity_in_stock", "Date", "Warehouse_type")
values (1, 46, '2024-06-05', 'Холодный');

insert into "Deliveries" (consignment_note_id, "Arrival_date", supplier_id, product_id, "Quantity", "Expiration_date")
values (1, '2024-06-04', 1, 1, 100, '2025-06-01');

insert into products_and_consignment_notes (product_id, consignment_note_id)
values (1, 1);

insert into "Allergens" ("Allergen", product_id)
values ('Мясо', 1);

insert into "Clients" ("Card_number", "Phone_number", "Discount_level")
values (0987567834561324, 89563452056, 1);

insert into "Dishes_and_Ingredients" (product_id, dish_id)
values (1, 1);

insert into "Receipts" ("Date", "Time", "Receipt_amount", waiter_id, client_id, "Payment_type")
values ('2025-04-04', '09:03:00', 800, 1, 1, 'Карта');

insert into "Sales" (dish_id, cook_id, receipt_id, "Sale_amount")
values (1, 1, 1, 800);
