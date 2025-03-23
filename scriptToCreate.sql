CREATE TABLE "Dishes" (
	"dish_id" SERIAL,
	"Name" TEXT NOT NULL,
	"Calories" INTEGER NOT NULL,
	"Type" TEXT,
	"Price" NUMERIC,
	PRIMARY KEY("dish_id")
);

CREATE TABLE "Warehouse" (
	"product_id" INT,
	"Quantity_in_stock" INTEGER,
	"Date" DATE NOT NULL,
	"Warehouse_type" TEXT NOT NULL,
	PRIMARY KEY("product_id")
);


CREATE TABLE "Dishes_and_Ingredients" (
	"recipe_id" SERIAL NOT NULL,
	"product_id" INTEGER NOT NULL,
	"Product_quantity" INTEGER,
	"dish_id" INTEGER NOT NULL,
	"Cooking_method" TEXT,
	PRIMARY KEY("recipe_id")
);


CREATE TABLE "Deliveries" (
	"consignment_note_id" BIGINT,
	"Arrival_date" DATE NOT NULL,
	"supplier_id" INTEGER,
	"product_id" INTEGER NOT NULL,
	"Quantity" INTEGER NOT NULL,
	"Expiration_date" DATE,
	PRIMARY KEY("consignment_note_id")
);


CREATE TABLE "Suppliers" (
	"supplier_id" SERIAL,
	"Name" TEXT NOT NULL,
	PRIMARY KEY("supplier_id")
);


CREATE TABLE "Receipts" ( -- чеки
	"receipt_id" SERIAL,
	"Date" DATE NOT NULL,
	"Time" TIME NOT NULL,
	"waiter_id" INTEGER,
	"Receipt_amount" REAL NOT NULL,
	"client_id" INTEGER,
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
	"receipt_id" INTEGER NOT NULL,
	"Sale_amount" REAL NOT NULL,
	PRIMARY KEY("sale_id")
);

CREATE TABLE "Allergens" (
	"allergen_id" SERIAL,
	"Allergen" TEXT NOT NULL,
	"product_id" INTEGER NOT NULL,
	PRIMARY KEY("allergen_id")
);


CREATE TABLE "Clients" (
	"client_id" SERIAL,
	"Discount_level" SMALLINT,
	"Card_number" BIGINT,
	"Phone_number" BIGINT,
	PRIMARY KEY("client_id")
);


create table "Products" (
	"product_id" SERIAL PRIMARY key, 
	"Product_name" TEXT NOT NULL
);
