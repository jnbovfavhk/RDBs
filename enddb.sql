CREATE TABLE "Dishes" (
	"dish_id" SERIAL,
	"Name" TEXT NOT NULL,
	"Calories" INTEGER NOT NULL,
	"Type" TEXT NOT NULL,
	"Price" NUMERIC,
	PRIMARY KEY("dish_id")
);

COMMENT ON TABLE "Dishes" IS 'Жареное, вареное...';


CREATE TABLE "Warehouse" (
	"product_id" SERIAL,
	"Quantity_in_stock" INTEGER NOT NULL,
	"Date" DATE NOT NULL,
	"Warehouse_type" TEXT NOT NULL,
	PRIMARY KEY("product_id")
);


CREATE TABLE "Dishes_and_Ingredients" (
	"recipe_id" INTEGER NOT NULL,
	"product_id" INTEGER NOT NULL UNIQUE,
	"Product_quantity" INTEGER NOT NULL,
	"dish_id" INTEGER NOT NULL,
	"Cooking_method" TEXT NOT NULL,
	PRIMARY KEY("recipe_id")
);


CREATE TABLE "Deliveries" (
	"consignment_note_id" SERIAL,
	"Quantity" INTEGER NOT NULL,
	"Arrival_date" DATE NOT NULL,
	"Date_expiration_date" DATE NOT NULL,
	"supplier_id" INTEGER NOT NULL,
	"product_id" INTEGER NOT NULL,
	PRIMARY KEY("consignment_note_id")
);


CREATE TABLE "Suppliers" (
	"supplier_id" SERIAL,
	"Name" TEXT NOT NULL,
	PRIMARY KEY("supplier_id")
);


CREATE TABLE "Receipts" (
	"receipt_id" SERIAL,
	"Date" DATE NOT NULL,
	"Time" TIME NOT NULL,
	"waiter_id" INTEGER NOT NULL,
	"Receipt_amount" REAL NOT NULL,
	"client_id" INTEGER NOT NULL,
	"Payment_type" TEXT NOT NULL,
	PRIMARY KEY("receipt_id")
);


CREATE TABLE "Employees" (
	"employee_id" SERIAL,
	"Position" TEXT NOT NULL,
	"Full_name" TEXT NOT NULL,
	"Experience" SMALLINT NOT NULL,
	"Phone_number" BIGINT NOT NULL,
	PRIMARY KEY("employee_id")
);


CREATE TABLE "Sales" (
	"sale_id" SERIAL,
	"dish_id" INTEGER NOT NULL,
	"cook_id" INTEGER NOT NULL,
	"receipt_id" INTEGER NOT NULL UNIQUE,
	"Sale_amount" REAL NOT NULL,
	PRIMARY KEY("sale_id")
);


CREATE TABLE "Allergens" (
	"allergen_id" SERIAL,
	"Allergen" TEXT NOT NULL,
	"product_id" INTEGER NOT NULL,
	PRIMARY KEY("allergen_id")
);


CREATE TABLE "Client" (
	"client_id" SERIAL,
	"Discount_level" SMALLINT NOT NULL,
	"Card_number" BIGINT,
	"Phone_number" BIGINT,
	PRIMARY KEY("client_id")
);


ALTER TABLE "Dishes_and_Ingredients"
ADD FOREIGN KEY("dish_id") REFERENCES "Dishes"("dish_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE "Dishes_and_Ingredients"
ADD FOREIGN KEY("product_id") REFERENCES "Warehouse"("product_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE "Deliveries"
ADD FOREIGN KEY("product_id") REFERENCES "Warehouse"("product_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE "Sales"
ADD FOREIGN KEY("dish_id") REFERENCES "Dishes"("dish_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE "Sales"
ADD FOREIGN KEY("cook_id") REFERENCES "Employees"("employee_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE "Sales"
ADD FOREIGN KEY("receipt_id") REFERENCES "Receipts"("receipt_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE "Allergens"
ADD FOREIGN KEY("product_id") REFERENCES "Dishes_and_Ingredients"("product_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE "Deliveries"
ADD FOREIGN KEY("supplier_id") REFERENCES "Suppliers"("supplier_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE "Receipts"
ADD FOREIGN KEY("waiter_id") REFERENCES "Employees"("employee_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE "Receipts"
ADD FOREIGN KEY("client_id") REFERENCES "Client"("client_id")
ON UPDATE NO ACTION ON DELETE NO ACTION;
