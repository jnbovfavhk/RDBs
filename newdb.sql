-- Table: Dishes
CREATE TABLE Dishes (
    dish_id SERIAL PRIMARY KEY,
    Name TEXT NOT NULL,
    Calories INTEGER NOT NULL,
    Type TEXT NOT NULL
);

-- Table: Warehouse
CREATE TABLE Warehouse (
    product_id SERIAL PRIMARY KEY,
    Quantity_in_stock INTEGER NOT NULL,
    Date DATE NOT NULL,
    Warehouse_type TEXT NOT NULL
);

-- Table: Dishes_and_Ingredients
CREATE TABLE Dishes_and_Ingredients (
    recipe_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL UNIQUE,
    Product_quantity INTEGER NOT NULL,
    dish_id INTEGER NOT NULL,
    Cooking_method TEXT NOT NULL,
    PRIMARY KEY (recipe_id),
    FOREIGN KEY (dish_id) REFERENCES Dishes(dish_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (product_id) REFERENCES Warehouse(product_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Table: Deliveries
CREATE TABLE Deliveries (
    consignment_note_id SERIAL PRIMARY KEY,
    Quantity INTEGER NOT NULL,
    Arrival_date DATE NOT NULL,
    Date_expiration_date DATE NOT NULL,
    supplier_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (product_id) REFERENCES Warehouse(product_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Table: Suppliers
CREATE TABLE Suppliers (
    supplier_id SERIAL PRIMARY KEY,
    Name TEXT NOT NULL
);

-- Table: Receipts
CREATE TABLE Receipts (
    receipt_id SERIAL PRIMARY KEY,
    Date DATE NOT NULL,
    Time TIME NOT NULL,
    waiter_id INTEGER NOT NULL,
    Receipt_amount REAL NOT NULL,
    client_id INTEGER NOT NULL,
    Payment_type TEXT NOT NULL,
    FOREIGN KEY (waiter_id) REFERENCES Employees(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (client_id) REFERENCES Client(client_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Table: Employees
CREATE TABLE Employees (
    employee_id SERIAL PRIMARY KEY,
    Position TEXT NOT NULL,
    Full_name TEXT NOT NULL,
    Experience SMALLINT NOT NULL,
    Phone_number BIGINT NOT NULL
);

-- Table: Sales
CREATE TABLE Sales (
    sale_id SERIAL PRIMARY KEY,
    dish_id INTEGER NOT NULL,
    cook_id INTEGER NOT NULL,
    Date DATE NOT NULL,
    receipt_id INTEGER NOT NULL UNIQUE,
    Sales_amount REAL NOT NULL,
    FOREIGN KEY (dish_id) REFERENCES Dishes(dish_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (cook_id) REFERENCES Employees(employee_id) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (receipt_id) REFERENCES Receipts(receipt_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Table: Allergens
CREATE TABLE Allergens (
    allergen_id SERIAL PRIMARY KEY,
    Allergen TEXT NOT NULL,
    product_id INTEGER NOT NULL,
    FOREIGN KEY (product_id) REFERENCES Dishes_and_Ingredients(product_id) ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Table: Client
CREATE TABLE Client (
    client_id SERIAL PRIMARY KEY,
    Discount_level SMALLINT NOT NULL
);
