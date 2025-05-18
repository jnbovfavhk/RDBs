ALTER TABLE "Dishes_and_Ingredients"
ADD FOREIGN KEY("dish_id") REFERENCES "Dishes"("dish_id")
ON update CASCADE ON DELETE CASCADE;

ALTER TABLE "Dishes_and_Ingredients"
ADD FOREIGN KEY("product_id") REFERENCES "Products"("product_id")
ON UPDATE SET NULL ON DELETE SET NULL;

ALTER TABLE "Deliveries"
ADD FOREIGN KEY("product_id") REFERENCES "Products"("product_id")
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE "Sales"
ADD FOREIGN KEY("dish_id") REFERENCES "Dishes"("dish_id")
ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE "Sales"
ADD FOREIGN KEY("cook_id") REFERENCES "Employees"("employee_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "Sales"
ADD FOREIGN KEY("receipt_id") REFERENCES "Receipts"("receipt_id")
ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE "Allergens_and_dishes"
ADD FOREIGN KEY("dish_id") REFERENCES "Dishes"("dish_id")
ON UPDATE CASCADE ON DELETE CASCADE;

alter table "Allergens_and_dishes"
add foreign key("allergen_id") references "Allergens"("allergen_id")
on update cascade on delete no action;

ALTER TABLE "Deliveries"
ADD FOREIGN KEY("supplier_id") REFERENCES "Suppliers"("supplier_id")
ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE "Receipts"
ADD FOREIGN KEY("waiter_id") REFERENCES "Employees"("employee_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "Receipts"
ADD FOREIGN KEY("client_id") REFERENCES "Clients"("client_id")
ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE "Warehouse"
ADD FOREIGN KEY ("product_id") REFERENCES "Products" ("product_id")
ON UPDATE CASCADE ON DELETE RESTRICT;
