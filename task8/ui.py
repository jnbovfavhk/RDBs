import sys
import psycopg2
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
                             QLabel, QTableWidget, QTableWidgetItem, QPushButton, QLineEdit,
                             QComboBox, QMessageBox, QTabWidget, QHeaderView, QDialog, QFormLayout, QDialogButtonBox,
                             QInputDialog)
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont, QIntValidator


class PaymentDialog(QDialog):
    """Диалог для ввода данных карты"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Введите данные карты")

        layout = QFormLayout()

        # Поле для номера карты
        self.card_number = QLineEdit()
        self.card_number.setPlaceholderText("1234 5678 9012 3456")
        self.card_number.setInputMask("9999 9999 9999 9999;_")
        layout.addRow("Номер карты:", self.card_number)

        # Поля для срока действия и CVV
        self.expiry = QLineEdit()
        self.expiry.setPlaceholderText("MM/ГГ")
        self.expiry.setInputMask("99/99;_")
        layout.addRow("Срок действия (MM/ГГ):", self.expiry)

        self.cvv = QLineEdit()
        self.cvv.setValidator(QIntValidator(100, 999))
        self.cvv.setMaxLength(3)
        self.cvv.setPlaceholderText("123")
        layout.addRow("CVV:", self.cvv)

        # Кнопки
        self.buttons = QDialogButtonBox(
            QDialogButtonBox.Ok | QDialogButtonBox.Cancel
        )
        self.buttons.accepted.connect(self.accept)
        self.buttons.rejected.connect(self.reject)

        layout.addRow(self.buttons)
        self.setLayout(layout)

    def get_data(self):
        return {
            "card_number": self.card_number.text().replace(" ", ""),
            "expiry": self.expiry.text(),
            "cvv": self.cvv.text()
        }


class RestaurantApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.current_client_id = None
        self.conn = self.connect_to_db()
        self.init_ui()

    def connect_to_db(self):
        try:
            return psycopg2.connect(
                dbname="postgres",
                user="postgres",
                password="jnuaLFFert",
                host="localhost"
            )
        except psycopg2.Error as e:
            QMessageBox.critical(self, "Ошибка", f"Не удалось подключиться к базе данных:\n{str(e)}")
            sys.exit(1)

    def init_ui(self):
        self.setWindowTitle("Ресторан 'Гурман'")
        self.setGeometry(100, 100, 1000, 700)

        self.tabs = QTabWidget()
        self.setCentralWidget(self.tabs)

        # Вкладка меню
        self.menu_tab = QWidget()
        self.init_menu_tab()
        self.tabs.addTab(self.menu_tab, "Меню")

        # Вкладка заказа
        self.order_tab = QWidget()
        self.init_order_tab()
        self.tabs.addTab(self.order_tab, "Мой заказ")

        self.show_auth_dialog()

    def init_menu_tab(self):
        layout = QVBoxLayout()

        # Фильтры
        filter_layout = QHBoxLayout()
        self.type_combo = QComboBox()
        self.type_combo.addItem("Все категории")
        self.allergen_combo = QComboBox()
        self.allergen_combo.addItem("Все аллергены")

        filter_layout.addWidget(QLabel("Категория:"))
        filter_layout.addWidget(self.type_combo)
        filter_layout.addWidget(QLabel("Исключить аллергены:"))
        filter_layout.addWidget(self.allergen_combo)
        filter_layout.addStretch()

        # Таблица меню
        self.menu_table = QTableWidget()
        self.menu_table.setColumnCount(5)
        self.menu_table.setHorizontalHeaderLabels(["ID", "Название", "Категория", "Цена", "Аллергены"])
        self.menu_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.menu_table.setSelectionBehavior(QTableWidget.SelectRows)

        # Кнопка добавления в заказ
        add_button = QPushButton("Добавить в заказ")
        add_button.clicked.connect(self.add_to_order)


        layout.addLayout(filter_layout)
        layout.addWidget(self.menu_table)
        layout.addWidget(add_button)

        self.menu_tab.setLayout(layout)
        self.load_filters()
        self.load_menu()

        self.type_combo.currentIndexChanged.connect(self.load_menu)
        self.allergen_combo.currentIndexChanged.connect(self.load_menu)

    def init_order_tab(self):
        layout = QVBoxLayout()

        # Таблица заказа
        self.order_table = QTableWidget()
        self.order_table.setColumnCount(4)
        self.order_table.setHorizontalHeaderLabels(["ID", "Название", "Количество", "Сумма"])
        self.order_table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)

        # Итого
        self.total_label = QLabel("Итого: 0.00 руб.")
        self.total_label.setFont(QFont("Arial", 14, QFont.Bold))

        # Кнопки
        button_layout = QHBoxLayout()
        checkout_button = QPushButton("Оформить заказ")
        checkout_button.clicked.connect(self.checkout_order)
        clear_button = QPushButton("Очистить заказ")
        clear_button.clicked.connect(self.clear_order)

        button_layout.addWidget(checkout_button)
        button_layout.addWidget(clear_button)

        layout.addWidget(self.order_table)
        layout.addWidget(self.total_label)
        layout.addLayout(button_layout)

        self.order_tab.setLayout(layout)

    def show_auth_dialog(self):
        dialog = QDialog(self)
        dialog.setWindowTitle("Авторизация")
        dialog.setModal(True)

        layout = QVBoxLayout()
        phone_label = QLabel("Введите номер телефона или закройте окно для входа гостем:")
        self.phone_input = QLineEdit()
        auth_button = QPushButton("Продолжить")
        auth_button.clicked.connect(lambda: self.handle_auth(dialog))

        layout.addWidget(phone_label)
        layout.addWidget(self.phone_input)
        layout.addWidget(auth_button)
        dialog.setLayout(layout)

        # Обработка закрытия диалога
        if dialog.exec_() == QDialog.Rejected:
            reply = QMessageBox.question(
                self, 'Гостевой вход',
                'Вы хотите продолжить как гость? У некоторых функций будут ограничения.',
                QMessageBox.Yes | QMessageBox.No, QMessageBox.Yes
            )
            if reply == QMessageBox.No:
                sys.exit()

    def handle_auth(self, dialog):
        phone = self.phone_input.text().strip()

        # Разрешаем гостевой вход при пустом поле
        if not phone:
            dialog.reject()
            return

        # Проверка базового формата номера
        if len(phone) != 11 or not phone.startswith('7') or not phone.isdigit():
            QMessageBox.warning(self, "Ошибка", "Номер должен состоять из 11 цифр и начинаться с 7!")
            return

        try:
            phone_number = int(phone)
        except ValueError:
            QMessageBox.warning(self, "Ошибка", "Номер должен содержать только цифры!")
            return

        try:
            with self.conn.cursor() as cur:
                # Поиск существующего клиента
                cur.execute(
                    'SELECT "client_id" FROM "Clients" WHERE "Phone_number" = %s',
                    (phone_number,)
                )
                client = cur.fetchone()

                if client:
                    self.current_client_id = client[0]
                    msg = f"Добро пожаловать! Ваш ID: {self.current_client_id}"
                else:
                    # Регистрация нового клиента
                    cur.execute(
                        'INSERT INTO "Clients" ("Phone_number") VALUES (%s) RETURNING "client_id"',
                        (phone_number,)
                    )
                    self.current_client_id = cur.fetchone()[0]
                    self.conn.commit()
                    msg = f"Вы зарегистрированы! Ваш ID: {self.current_client_id}"

                QMessageBox.information(self, "Успех", msg)
                dialog.accept()  # Корректное закрытие диалога

        except psycopg2.Error as e:
            self.conn.rollback()
            QMessageBox.critical(
                self,
                "Ошибка",
                f"Ошибка базы данных:\n{str(e)}"
            )
        except Exception as e:
            QMessageBox.critical(
                self,
                "Ошибка",
                f"Непредвиденная ошибка:\n{str(e)}"
            )

    def load_filters(self):
        try:
            with self.conn.cursor() as cur:
                # Загрузка категорий
                cur.execute("SELECT DISTINCT \"Type\" FROM \"Dishes\" WHERE \"Type\" IS NOT NULL")
                types = [row[0] for row in cur.fetchall()]
                self.type_combo.addItems(types)

                # Загрузка аллергенов
                cur.execute("SELECT \"Allergen\" FROM \"Allergens\" ORDER BY \"Allergen\"")
                allergens = [row[0] for row in cur.fetchall()]
                self.allergen_combo.addItems(allergens)

        except psycopg2.Error as e:
            QMessageBox.critical(self, "Ошибка", f"Ошибка загрузки фильтров: {str(e)}")

    def load_menu(self):
        try:
            with self.conn.cursor() as cur:
                # Базовый запрос
                base_query = """
                    SELECT 
                        d.dish_id, 
                        d."Name", 
                        d."Type", 
                        d."Price", 
                        COALESCE(STRING_AGG(a."Allergen", ', '), 'Нет аллергенов') AS allergens
                    FROM "Dishes" d
                    LEFT JOIN "Allergens_and_dishes" ad ON d.dish_id = ad.dish_id
                    LEFT JOIN "Allergens" a ON ad.allergen_id = a.allergen_id
                """

                where_clauses = []
                having_clauses = []
                params = []

                # Фильтр по категории
                selected_type = self.type_combo.currentText()
                if selected_type != "Все категории":
                    where_clauses.append("d.\"Type\" = %s")
                    params.append(selected_type)

                # Фильтр по аллергенам
                selected_allergen = self.allergen_combo.currentText()
                if selected_allergen != "Все аллергены":
                    # Исключаем блюда, содержащие выбранный аллерген
                    having_clauses.append("NOT bool_or(a.\"Allergen\" = %s)")
                    params.append(selected_allergen)

                # Собираем полный запрос
                full_query = base_query

                if where_clauses:
                    full_query += " WHERE " + " AND ".join(where_clauses)

                full_query += " GROUP BY d.dish_id, d.\"Name\", d.\"Type\", d.\"Price\""

                if having_clauses:
                    full_query += " HAVING " + " AND ".join(having_clauses)

                full_query += " ORDER BY d.\"Type\", d.\"Name\";"

                # Выполняем запрос
                cur.execute(full_query, params)
                menu_items = cur.fetchall()

                # Обновляем таблицу
                self.menu_table.setRowCount(len(menu_items))
                for row_idx, row in enumerate(menu_items):
                    for col_idx, item in enumerate(row):
                        table_item = QTableWidgetItem(str(item))
                        table_item.setFlags(Qt.ItemIsSelectable | Qt.ItemIsEnabled)
                        self.menu_table.setItem(row_idx, col_idx, table_item)

        except psycopg2.Error as e:
            QMessageBox.critical(self, "Ошибка", f"Ошибка загрузки меню: {str(e)}")

    def add_to_order(self):
        selected = self.menu_table.selectionModel().selectedRows()
        if not selected:
            QMessageBox.warning(self, "Ошибка", "Выберите блюдо из меню!")
            return

        dish_id = int(self.menu_table.item(selected[0].row(), 0).text())
        dish_name = self.menu_table.item(selected[0].row(), 1).text()
        price = float(self.menu_table.item(selected[0].row(), 3).text())

        # Проверка на уже добавленное блюдо
        for row in range(self.order_table.rowCount()):
            if int(self.order_table.item(row, 0).text()) == dish_id:
                qty = int(self.order_table.item(row, 2).text()) + 1
                self.order_table.setItem(row, 2, QTableWidgetItem(str(qty)))
                self.order_table.setItem(row, 3, QTableWidgetItem(f"{qty * price:.2f}"))
                self.update_total()
                return

        # Добавление нового блюда в заказ
        row_pos = self.order_table.rowCount()
        self.order_table.insertRow(row_pos)
        self.order_table.setItem(row_pos, 0, QTableWidgetItem(str(dish_id)))
        self.order_table.setItem(row_pos, 1, QTableWidgetItem(dish_name))
        self.order_table.setItem(row_pos, 2, QTableWidgetItem("1"))
        self.order_table.setItem(row_pos, 3, QTableWidgetItem(f"{price:.2f}"))
        self.update_total()

    def update_total(self):
        total = 0.0
        for row in range(self.order_table.rowCount()):
            total += float(self.order_table.item(row, 3).text())
        self.total_label.setText(f"Итого: {total:.2f} руб.")

    def clear_order(self):
        self.order_table.setRowCount(0)
        self.update_total()

    def checkout_order(self):
        if self.order_table.rowCount() == 0:
            QMessageBox.warning(self, "Ошибка", "Ваш заказ пуст!")
            return

        # Выбор способа оплаты
        payment, ok = QInputDialog.getItem(
            self, "Способ оплаты", "Выберите способ оплаты:",
            ["Наличные", "Карта"], 0, False
        )

        if not ok:
            return

        # Обработка оплаты картой
        if payment == "Карта":
            dlg = PaymentDialog(self)
            if dlg.exec_() != QDialog.Accepted:
                return

            card_data = dlg.get_data()
            if len(card_data["card_number"]) != 16 or not card_data["card_number"].isdigit():
                QMessageBox.warning(self, "Ошибка", "Неверный номер карты!")
                return

        try:
            with self.conn.cursor() as cur:
                # Получаем любого повара один раз для всего заказа
                cur.execute("""
                    SELECT employee_id FROM "Employees" 
                    WHERE "Position" ILIKE '%%повар%%' 
                    AND hiring = TRUE
                    LIMIT 1
                """)
                cook_id = cur.fetchone()[0]

                # Создание чека
                cur.execute("""
                    INSERT INTO "Receipts" (
                        "Date", "Time", "client_id", "Receipt_amount", "Payment_type"
                    ) VALUES (
                        CURRENT_DATE, CURRENT_TIME, %s, %s, %s
                    ) RETURNING receipt_id
                """, (
                    self.current_client_id,
                    float(self.total_label.text().split()[-2]),
                    payment
                ))

                receipt_id = cur.fetchone()[0]

                # Добавляем все позиции заказа
                for row in range(self.order_table.rowCount()):
                    dish_id = int(self.order_table.item(row, 0).text())
                    quantity = int(self.order_table.item(row, 2).text())
                    price = float(self.order_table.item(row, 3).text()) / quantity  # Получаем цену за единицу
                    amount = price * quantity

                    cur.execute("""
                        INSERT INTO "Sales" (
                            dish_id, cook_id, receipt_id, "Sale_amount"
                        ) VALUES (%s, %s, %s, %s)
                    """, (dish_id, cook_id, receipt_id, amount))

                self.conn.commit()
                QMessageBox.information(self, "Успех", f"Заказ №{receipt_id} оформлен!\nСпособ оплаты: {payment}")
                self.clear_order()

        except psycopg2.Error as e:
            self.conn.rollback()
            QMessageBox.critical(self, "Ошибка", f"Ошибка оформления заказа: {str(e)}")

    def closeEvent(self, event):
        if self.conn:
            self.conn.close()
        event.accept()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = RestaurantApp()
    window.show()
    sys.exit(app.exec_())
