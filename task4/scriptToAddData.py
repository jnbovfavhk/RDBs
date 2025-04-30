import psycopg2
from faker import Faker
import random
from datetime import datetime, timedelta

# Настройки подключения
conn_params = {
    'dbname': "postgres",
    'user': "postgres",
    'password': "jnuaLFFert",
    'host': "localhost"
}

fake = Faker('ru_RU')


def full_allergens(conn, cursor):
    print("Заполнение Allergens...")
    allergens = ['Орехи', 'Молоко', 'Яйца', 'Рыба', 'Глютен', 'Морепродукты', 'Арахис', 'Соя']
    print("aaa")
    cursor.executemany(
        "INSERT INTO \"Allergens\" (\"Allergen\") VALUES (%s)",
        [(a,) for a in allergens]
    )

    conn.commit()
    print("Завершено")


def full_products(conn, cursor):
    print("Заполнение Prdoucts")
    products = [fake.word() for _ in range(100000)]
    cursor.executemany(
        "INSERT INTO \"Products\" (\"Product_name\") VALUES (%s)",
        [(p,) for p in products]
    )
    conn.commit()
    print("Завершено")


def full_dishes(conn, cursor):
    print("Заполнение dishes")
    dish_types = ['Суп', 'Салат', 'Гарнир', 'Основное', 'Десерт', 'Напиток']

    for _ in range(100000):
        cursor.execute(
            "INSERT INTO \"Dishes\" (\"Name\", \"Calories\", \"Type\", \"Price\") VALUES (%s, %s, %s, %s)",
            (fake.word(), random.randint(50, 2000), random.choice(dish_types),
             round(random.uniform(100, 2000), 2)))

    conn.commit()
    print("Завершено")


def full_suppliers(conn, cursor):
    print("Заполнение Suppliers")
    for _ in range(100000):
        supplier_type = random.choice(['ООО', 'ИП', 'АО', 'ПАО', 'НКО', 'ОП'])
        cursor.execute(
            "INSERT INTO \"Suppliers\" (\"Name\") VALUES (%s)",
            (f"{supplier_type} {fake.company()}",)
        )

    conn.commit()
    print("Завершено")


def full_employees(conn, cursor):
    print("Заполнение Employees")
    positions = ['Официант', 'Повар', 'Менеджер', 'Бармен', 'Администратор']
    for _ in range(100000):
        cursor.execute(
            "INSERT INTO \"Employees\" (\"Position\", \"Full_name\", \"Experience\", \"Phone_number\", \"Salary\") VALUES (%s, %s, %s, %s, %s)",
            (random.choice(positions), fake.name(), random.randint(0, 30), fake.unique.msisdn(),
             random.randint(20000, 150000))
        )
    conn.commit()
    print("Завершено")


def full_clients(conn, cursor):
    print("Заполнение Clients")
    for _ in range(100000):
        cursor.execute(
            "INSERT INTO \"Clients\" (\"Discount_level\", \"Card_number\", \"Phone_number\") VALUES (%s, %s, %s)",
            (random.randint(0, 3), fake.unique.credit_card_number(), fake.unique.msisdn())
        )
    conn.commit()
    print("Завершено")


def full_receipts(conn, cursor):
    print("Заполнение Receipts")
    employee_ids = list(range(1, 100001))
    client_ids = list(range(1, 100001))
    for _ in range(100000):
        cursor.execute(
            "INSERT INTO \"Receipts\" (\"Date\", \"Time\", \"waiter_id\", \"Receipt_amount\", \"client_id\", \"Payment_type\") VALUES (%s, %s, %s, %s, %s, %s)",
            (fake.date_between(start_date='-3y'), fake.time(), random.choice(employee_ids),
             round(random.uniform(500, 5000), 2), random.choice(client_ids), random.choice(['Наличные', 'Карта']))
        )

    conn.commit()
    print("Завершено")


def full_warehouse(conn, cursor):
    print("Заполнение warehouse")
    product_ids = list(range(1, 100001))
    for _ in range(100000):
        cursor.execute(
            "INSERT INTO \"Warehouse\" (\"product_id\", \"Quantity_in_stock\", \"Date\", \"Warehouse_type\") VALUES (%s, %s, %s, %s)",
            (random.choice(product_ids), random.randint(0, 1000), fake.date_between(start_date='-3y'),
             random.choice(['Холодный склад', 'Морозильная камера', 'Сухой склад'])))

    conn.commit()
    print("Завершено")

def full_deliveries(conn, cursor):
    print("Заполнение Deliveries")
    supplier_ids = list(range(1, 100001))
    product_ids = list(range(1, 100001))
    for i in range(100000):
        cursor.execute(
            "INSERT INTO \"Deliveries\" (\"consignment_note_id\", \"Arrival_date\", \"supplier_id\", \"product_id\", \"Quantity\", \"Expiration_date\") VALUES (%s, %s, %s, %s, %s, %s)",
            (i + 1, fake.date_between(start_date='-1y'), random.choice(supplier_ids), random.choice(product_ids),
             random.randint(10, 500), fake.date_between(start_date='-3y', end_date='+1y')))

    conn.commit()
    print("Завершено")

def full_sales(conn, cursor):
    print("Заполнение Sales")
    dish_ids = list(range(1, 100001))
    receipt_ids = list(range(1, 100001))
    employee_ids = list(range(1, 100001))
    cook_ids = [id for id in employee_ids if random.random() > 0.7]  # Примерно 30% сотрудников - повара
    for _ in range(100000):
        cursor.execute(
            "INSERT INTO \"Sales\" (\"dish_id\", \"cook_id\", \"receipt_id\", \"Sale_amount\") VALUES (%s, %s, %s, %s)",
            (random.choice(dish_ids), random.choice(cook_ids), random.choice(receipt_ids),
             round(random.uniform(100, 2000), 2)))

    conn.commit()
    print("Завершено")


def full_allergens_and_dishes(conn, cursor):
    print("Заполнение Allergens and Dishes")
    allergens = ['Орехи', 'Молоко', 'Яйца', 'Рыба', 'Глютен', 'Морепродукты', 'Арахис', 'Соя']
    allergen_ids = list(range(1, len(allergens) + 1))
    dish_ids = list(range(1, 100001))
    for _ in range(100000):
        cursor.execute(
            "INSERT INTO \"Allergens_and_dishes\" (\"allergen_id\", \"dish_id\") VALUES (%s, %s)",
            (random.choice(allergen_ids), random.choice(dish_ids))
        )

    conn.commit()
    print("Завершено")

def full_dishes_and_ingredients(conn, cursor):
    print("Заполнение Dishes_and_Ingredients")
    product_ids = list(range(1, 100001))
    dish_ids = list(range(1, 100001))
    cooking_methods = ['Варить', 'Жарить', 'Запекать', 'Тушить', 'Смешать']
    for _ in range(100000):
        cursor.execute(
            "INSERT INTO \"Dishes_and_Ingredients\" (\"product_id\", \"Product_quantity\", \"dish_id\", \"Cooking_method\") VALUES (%s, %s, %s, %s)",
            (
            random.choice(product_ids), random.randint(1, 500), random.choice(dish_ids), random.choice(cooking_methods)))

    conn.commit()
    print("Завершено")


def organize_connection():
    conn = psycopg2.connect(**conn_params)
    cursor = conn.cursor()
    return conn, cursor


conn, cursor = organize_connection()

full_allergens(conn, cursor)
full_products(conn, cursor)
full_dishes(conn, cursor)
full_suppliers(conn, cursor)
full_employees(conn, cursor)
full_clients(conn, cursor)
full_receipts(conn, cursor)
full_warehouse(conn, cursor)
full_deliveries(conn, cursor)
full_sales(conn, cursor)
full_allergens_and_dishes(conn, cursor)
full_dishes_and_ingredients(conn, cursor)
