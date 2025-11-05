#include "DatabaseManager.h"

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent)
{
    if (!initializeDatabase()) {
        qDebug() << "Failed to initialize database";
    }
}

DatabaseManager::~DatabaseManager()
{
    if (_database.isOpen()) {
        _database.close();
    }

    QString connectionName = _database.connectionName();

    QSqlDatabase::removeDatabase(connectionName);
}

bool DatabaseManager::initializeDatabase() {
    _database = QSqlDatabase::addDatabase("QSQLITE");
    _database.setDatabaseName("BagetWorkshopDB.db");

    if (!_database.open()) {
        qDebug() << "Сouldn't connect to the database: " << _database.lastError().text();
        return false;
    }

    qDebug() << "Database created at:" << QDir::currentPath() + "/BagetWorkshopDB.db";
    createTables();

    return true;
}

void DatabaseManager::createTables() {
    QSqlQuery query;

    // таблица пользователей
    QString createTableUsersQuery = "CREATE TABLE IF NOT EXISTS users ("
                                    "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                    "login TEXT UNIQUE NOT NULL, "
                                    "password TEXT NOT NULL, "
                                    "role TEXT NOT NULL CHECK(role IN ('Продавец', 'Мастер производства')), "
                                    "created_at DATETIME DEFAULT CURRENT_TIMESTAMP)";

    if (!query.exec(createTableUsersQuery)) {
        qDebug() << "Error creating users table:" << query.lastError();
        return;
    }

    // таблица покупателей
    QString createTableCustomers = "CREATE TABLE IF NOT EXISTS customers ("
                                   "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                   "full_name TEXT NOT NULL, "
                                   "phone TEXT, "
                                   "email TEXT, "
                                   "address TEXT, "
                                   "created_by INTEGER NOT NULL, "
                                   "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
                                   "FOREIGN KEY (created_by) REFERENCES users(id))";

    if (!query.exec(createTableCustomers)) {
        qDebug() << "Error creating customers table:" << query.lastError();
        return;
    }

    // таблица материалов для рамок
    QString createTableFrameMaterials = "CREATE TABLE IF NOT EXISTS frame_materials ("
                                        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                        "name TEXT NOT NULL, "
                                        "type TEXT NOT NULL, "
                                        "price_per_meter REAL NOT NULL, "
                                        "stock_quantity REAL DEFAULT 0, "
                                        "color TEXT, "
                                        "width REAL, "
                                        "created_by INTEGER NOT NULL, "
                                        "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
                                        "FOREIGN KEY (created_by) REFERENCES users(id))";

    if (!query.exec(createTableFrameMaterials)) {
        qDebug() << "Error creating frame_materials table:" << query.lastError();
        return;
    }

    // таблица комплектующей фурнитуры
    QString createTableComponentFurniture = "CREATE TABLE IF NOT EXISTS component_furniture ("
                                            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                            "name TEXT NOT NULL, "
                                            "type TEXT NOT NULL, "
                                            "price_per_unit REAL NOT NULL, "
                                            "stock_quantity INTEGER DEFAULT 0, "
                                            "created_by INTEGER NOT NULL, "
                                            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
                                            "FOREIGN KEY (created_by) REFERENCES users(id))";

    if (!query.exec(createTableComponentFurniture)) {
        qDebug() << "Error creating component_furniture table:" << query.lastError();
        return;
    }

    // таблица наборов вышивки
    QString createTableEmbroideryKits = "CREATE TABLE IF NOT EXISTS embroidery_kits ("
                                        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                        "name TEXT NOT NULL, "
                                        "description TEXT, "
                                        "price REAL NOT NULL, "
                                        "stock_quantity INTEGER DEFAULT 0, "
                                        "created_by INTEGER NOT NULL, "
                                        "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
                                        "is_active BOOLEAN DEFAULT 1, "
                                        "FOREIGN KEY (created_by) REFERENCES users(id))";

    if (!query.exec(createTableEmbroideryKits)) {
        qDebug() << "Error creating embroidery_kits table:" << query.lastError();
        return;
    }

    // таблица расходной фурнитуры
    QString createTableConsumableFurniture = "CREATE TABLE IF NOT EXISTS consumable_furniture ("
                                             "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                             "name TEXT NOT NULL, "
                                             "type TEXT NOT NULL, "
                                             "price_per_unit REAL NOT NULL, "
                                             "stock_quantity INTEGER DEFAULT 0, "
                                             "unit TEXT NOT NULL, "
                                             "created_by INTEGER NOT NULL, "
                                             "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
                                             "FOREIGN KEY (created_by) REFERENCES users(id))";

    if (!query.exec(createTableConsumableFurniture)) {
        qDebug() << "Error creating consumable_furniture table:" << query.lastError();
        return;
    }

    // таблица заказов
    QString createTableOrders = "CREATE TABLE IF NOT EXISTS orders ("
                                "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                "order_number TEXT UNIQUE NOT NULL, "
                                "customer_id INTEGER NOT NULL, "
                                "order_type TEXT NOT NULL CHECK(order_type IN ('Изготовление рамки', 'Продажа набора')), "
                                "total_amount REAL NOT NULL, "
                                "status TEXT NOT NULL CHECK(status IN ('Новый', 'В работе', 'Готов', 'Завершён', 'Отменён')), "
                                "created_by INTEGER NOT NULL, "
                                "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
                                "completed_at DATETIME, "
                                "FOREIGN KEY (customer_id) REFERENCES customers(id), "
                                "FOREIGN KEY (created_by) REFERENCES users(id))";

    if (!query.exec(createTableOrders)) {
        qDebug() << "Error creating orders table:" << query.lastError();
        return;
    }

    // таблица заказов на рамки
    QString createTableFrameOrders = "CREATE TABLE IF NOT EXISTS frame_orders ("
                                     "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                     "order_id INTEGER NOT NULL, "
                                     "width REAL NOT NULL, "
                                     "height REAL NOT NULL, "
                                     "frame_material_id INTEGER NOT NULL, "
                                     "component_furniture_id INTEGER NOT NULL, "
                                     "special_instructions TEXT, "
                                     "production_cost REAL NOT NULL, "
                                     "selling_price REAL NOT NULL, "
                                     "FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE, "
                                     "FOREIGN KEY (frame_material_id) REFERENCES frame_materials(id), "
                                     "FOREIGN KEY (component_furniture_id) REFERENCES component_furniture(id))";

    if (!query.exec(createTableFrameOrders)) {
        qDebug() << "Error creating frame_orders table:" << query.lastError();
        return;
    }

    // таблица позиций заказа
    QString createTableOrderItems = "CREATE TABLE IF NOT EXISTS order_items ("
                                    "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                                    "order_id INTEGER NOT NULL, "
                                    "item_type TEXT NOT NULL CHECK(item_type IN ('Готовый набор', 'Фурнитура')), "
                                    "item_id INTEGER NOT NULL, "
                                    "quantity INTEGER NOT NULL, "
                                    "unit_price REAL NOT NULL, "
                                    "total_price REAL NOT NULL, "
                                    "FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE)";

    if (!query.exec(createTableOrderItems)) {
        qDebug() << "Error creating order_items table:" << query.lastError();
        return;
    }

    // заполнение тестовыми данными
    insertTestData();
}

void DatabaseManager::insertTestData() {
    QSqlQuery query;

    query.exec("SELECT COUNT(*) FROM users");
    query.next();
    int userCount = query.value(0).toInt();

    if (userCount == 0) {
        query.prepare("INSERT INTO users (login, password, role) VALUES (?, ?, ?)");

        query.addBindValue("seller1");
        query.addBindValue("password123");
        query.addBindValue("Продавец");
        query.exec();

        query.addBindValue("master1");
        query.addBindValue("password123");
        query.addBindValue("Мастер производства");
        query.exec();

        qDebug() << "Test users inserted successfully";
    }

    query.exec("SELECT COUNT(*) FROM frame_materials");
    query.next();
    int materialsCount = query.value(0).toInt();

    if (materialsCount == 0) {
        query.exec("SELECT id FROM users WHERE login = 'master1'");
        int masterId = 0;
        if (query.next()) {
            masterId = query.value(0).toInt();
        }

        query.exec("SELECT id FROM users WHERE login = 'seller1'");
        int sellerId = 0;
        if (query.next()) {
            sellerId = query.value(0).toInt();
        }

        if (masterId > 0) {
            query.prepare("INSERT INTO frame_materials (name, type, price_per_meter, stock_quantity, color, width, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)");

            query.addBindValue("Дуб золотой");
            query.addBindValue("дерево");
            query.addBindValue(450.00);
            query.addBindValue(25.5);
            query.addBindValue("золотой");
            query.addBindValue(4.5);
            query.addBindValue(masterId);
            query.exec();

            query.addBindValue("Орех классический");
            query.addBindValue("дерево");
            query.addBindValue(520.00);
            query.addBindValue(18.2);
            query.addBindValue("коричневый");
            query.addBindValue(5.0);
            query.addBindValue(masterId);
            query.exec();

            query.addBindValue("Алюминий серебро");
            query.addBindValue("металл");
            query.addBindValue(380.00);
            query.addBindValue(32.8);
            query.addBindValue("серебряный");
            query.addBindValue(3.2);
            query.addBindValue(masterId);
            query.exec();

            query.prepare("INSERT INTO component_furniture (name, type, price_per_unit, stock_quantity, created_by) VALUES (?, ?, ?, ?, ?)");

            query.addBindValue("Уголок металлический");
            query.addBindValue("уголки");
            query.addBindValue(15.50);
            query.addBindValue(100);
            query.addBindValue(masterId);
            query.exec();

            query.addBindValue("Подвес для картины");
            query.addBindValue("подвесы");
            query.addBindValue(8.00);
            query.addBindValue(200);
            query.addBindValue(masterId);
            query.exec();
        }

        if (sellerId > 0) {
            query.prepare("INSERT INTO embroidery_kits (name, description, price, stock_quantity, created_by) VALUES (?, ?, ?, ?, ?)");

            query.addBindValue("Цветочная композиция");
            query.addBindValue("Набор для вышивки цветочной композиции");
            query.addBindValue(1200.00);
            query.addBindValue(15);
            query.addBindValue(sellerId);
            query.exec();

            query.addBindValue("Пейзаж с озером");
            query.addBindValue("Набор для вышивки пейзажа с озером и горами");
            query.addBindValue(1500.00);
            query.addBindValue(8);
            query.addBindValue(sellerId);
            query.exec();

            query.prepare("INSERT INTO consumable_furniture (name, type, price_per_unit, stock_quantity, unit, created_by) VALUES (?, ?, ?, ?, ?, ?)");

            query.addBindValue("Иглы для вышивания");
            query.addBindValue("инструменты");
            query.addBindValue(5.00);
            query.addBindValue(50);
            query.addBindValue("шт");
            query.addBindValue(sellerId);
            query.exec();

            query.addBindValue("Нитки мулине");
            query.addBindValue("материалы");
            query.addBindValue(12.00);
            query.addBindValue(100);
            query.addBindValue("набор");
            query.addBindValue(sellerId);
            query.exec();

            query.prepare("INSERT INTO customers (full_name, phone, email, address, created_by) VALUES (?, ?, ?, ?, ?)");

            query.addBindValue("Петров Иван Сергеевич");
            query.addBindValue("+7-912-345-67-89");
            query.addBindValue("petrov@mail.ru");
            query.addBindValue("г. Москва, ул. Ленина, д. 10");
            query.addBindValue(sellerId);
            query.exec();

            query.addBindValue("Смирнова Ольга Викторовна");
            query.addBindValue("+7-923-456-78-90");
            query.addBindValue("smirnova@gmail.com");
            query.addBindValue("г. Москва, пр. Мира, д. 25, кв. 14");
            query.addBindValue(sellerId);
            query.exec();
        }

        qDebug() << "Test data inserted successfully";
    }
}

bool DatabaseManager::loginUser(const QString &login, const QString &password) {
    QSqlQuery query;

    query.prepare("SELECT id, role FROM users WHERE login = ? AND password = ?");
    query.addBindValue(login);
    query.addBindValue(password);

    if (!query.exec()) {
        qDebug() << "Login error:" << query.lastError();
        return false;
    }

    if (query.next()) {
        currentUserId = query.value(0).toInt();
        currentUserRole = query.value(1).toString();
        qDebug() << "Login successful. User ID: " << currentUserId << "Role: " << currentUserRole;
        return true;
    }

    qDebug() << "Login failed: invalid credentials";
    return false;
}

// Получить роль текущего пользователя
QString DatabaseManager::getCurrentUserRole() const {
    return currentUserRole;
}

// Получить ID текущего пользователя
int DatabaseManager::getCurrentUserId() const {
    return currentUserId;
}

// Проверить, является ли пользователь продавцом
bool DatabaseManager::isSeller() const {
    return currentUserRole == "Продавец";
}

// Проверить, является ли пользователь мастером
bool DatabaseManager::isMaster() const {
    return currentUserRole == "Мастер производства";
}

// Получение модели таблицы
QSqlQueryModel* DatabaseManager::getTableModel(const QString &name) {
    QSqlQueryModel *model = new QSqlQueryModel(this);

    qDebug() << "Loading table:" << name;

    QString queryStr = "SELECT * FROM " + name;
    model->setQuery(queryStr, _database);

    if (model->lastError().isValid()) {
        qDebug() << "Error loading table" << name << ":" << model->lastError().text();
    } else {
        qDebug() << "Table" << name << "loaded successfully, rows:" << model->rowCount();

        if (model->rowCount() > 0) {
            QSqlRecord record = model->record(0);
            qDebug() << "Table columns:";
            for (int i = 0; i < record.count(); ++i) {
                qDebug() << " -" << record.fieldName(i) << ":" << record.value(i);
            }
        }
    }

    return model;
}

// Получение имен столбцов в таблице
QString DatabaseManager::getColumnName(const QString &name, int index) {
    QSqlRecord record = _database.record(name);
    if (index >= 0 && index < record.count()) {
        return record.fieldName(index);
    }
    return "";
}

// Получение данных конкретной строки по индексу модели
QVariantMap DatabaseManager::getRowData(const QString &table, int row)
{
    QVariantMap result;

    QSqlQueryModel *model = getTableModel(table);
    if (model && row >= 0 && row < model->rowCount()) {
        QSqlRecord record = model->record(row);
        for (int i = 0; i < record.count(); ++i) {
            QString fieldName = record.fieldName(i);
            QVariant value = record.value(i);
            result[fieldName] = value;
        }

        qDebug() << "Row data for table" << table << "row" << row << ":" << result;
    } else {
        qDebug() << "Invalid row or model for getRowData, table:" << table << "row:" << row;
    }

    return result;
}

// Добавление нового покупателя
void DatabaseManager::addCustomer(const QString &name, const QString &phone, const QString &email, const QString &address)
{
    QSqlQuery query;
    query.prepare("INSERT INTO customers (full_name, phone, email, address, created_by) VALUES (?, ?, ?, ?, ?)");
    query.addBindValue(name);
    query.addBindValue(phone);
    query.addBindValue(email);
    query.addBindValue(address);
    query.addBindValue(currentUserId);

    if (!query.exec()) {
        qDebug() << "Error adding customer:" << query.lastError().text();
        return;
    }

    qDebug() << "Customer added successfully by user ID:" << currentUserId;
}

// Редактирование информации о покупателе
void DatabaseManager::updateCustomer(int row, const QString &name, const QString &phone, const QString &email, const QString &address)
{
    QSqlQueryModel *model = getTableModel("customers");
    if (!model || row < 0 || row >= model->rowCount()) {
        qDebug() << "Invalid row for update:" << row;
        return;
    }

    QSqlRecord record = model->record(row);
    int id = record.value("id").toInt();

    QSqlQuery query;
    query.prepare("UPDATE customers SET full_name = ?, phone = ?, email = ?, address = ? WHERE id = ?");
    query.addBindValue(name);
    query.addBindValue(phone);
    query.addBindValue(email);
    query.addBindValue(address);
    query.addBindValue(id);

    if (!query.exec()) {
        qDebug() << "Error updating customer:" << query.lastError().text();
        return;
    }

    qDebug() << "Customer updated successfully";
}

// Удаление покупателя
void DatabaseManager::deleteCustomer(int row)
{
    QSqlQueryModel *model = getTableModel("customers");
    if (!model || row < 0 || row >= model->rowCount()) {
        qDebug() << "Invalid row for deletion:" << row;
        return;
    }

    QSqlRecord record = model->record(row);
    int id = record.value("id").toInt();

    QSqlQuery query;
    query.prepare("DELETE FROM customers WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        qDebug() << "Error deleting customer:" << query.lastError().text();
        return;
    }

    qDebug() << "Customer deleted successfully";
}

// Количество записей в таблице
int DatabaseManager::getRowCount(const QString &table)
{
    QSqlQuery query;
    query.prepare("SELECT COUNT(*) FROM " + table);

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    return 0;
}

// Количество столбцов в таблице
int DatabaseManager::getColumnCount(const QString &table)
{
    QSqlRecord record = _database.record(table);
    return record.count();
}

// Получить списком заказы покупателя для вывода в окне CustomersPage
QVariantList DatabaseManager::getCustomerOrders(int customerId)
{
    QVariantList orders;

    QSqlQuery query;
    query.prepare("SELECT * FROM orders WHERE customer_id = ? ORDER BY created_at DESC");
    query.addBindValue(customerId);

    if (!query.exec()) {
        qDebug() << "Error getting customer orders:" << query.lastError().text();
        return orders;
    }

    while (query.next()) {
        QVariantMap order;
        QSqlRecord record = query.record();
        for (int i = 0; i < record.count(); ++i) {
            order[record.fieldName(i)] = record.value(i);
        }
        orders.append(order);
    }

    qDebug() << "Found" << orders.size() << "orders for customer ID:" << customerId;
    return orders;
}

// Получить модель клиентов для ComboBox
QSqlQueryModel* DatabaseManager::getCustomersModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    model->setQuery("SELECT id, full_name, phone, email FROM customers ORDER BY full_name", _database);
    return model;
}

// Получить модель наборов для вышивки
QSqlQueryModel* DatabaseManager::getEmbroideryKitsModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    model->setQuery("SELECT id, name, price FROM embroidery_kits WHERE is_active = 1 ORDER BY name", _database);
    return model;
}

// Создать новый заказ
bool DatabaseManager::createOrder(const QString &orderNumber, int customerId, const QString &orderType,
                                  double totalAmount, const QString &status, const QString &notes) {
    QSqlQuery query;
    query.prepare("INSERT INTO orders (order_number, customer_id, order_type, total_amount, status, created_by) "
                  "VALUES (?, ?, ?, ?, ?, ?)");
    query.addBindValue(orderNumber);
    query.addBindValue(customerId);
    query.addBindValue(orderType);
    query.addBindValue(totalAmount);
    query.addBindValue(status);
    query.addBindValue(currentUserId);

    if (!query.exec()) {
        qDebug() << "Error creating order:" << query.lastError().text();
        return false;
    }

    qDebug() << "Order created successfully:" << orderNumber;
    return true;
}

// Создать заказ на рамку
bool DatabaseManager::createFrameOrder(int orderId, double width, double height,
                                       int frameMaterialId, int componentFurnitureId,
                                       const QString &specialInstructions) {
    QSqlQuery query;
    query.prepare("INSERT INTO frame_orders (order_id, width, height, frame_material_id, "
                  "component_furniture_id, special_instructions, production_cost, selling_price) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    query.addBindValue(orderId);
    query.addBindValue(width);
    query.addBindValue(height);
    query.addBindValue(frameMaterialId);
    query.addBindValue(componentFurnitureId);
    query.addBindValue(specialInstructions);

    // Расчет стоимости (упрощенный)
    double productionCost = (width * height / 10000) * 500; // 500 руб за кв.м
    double sellingPrice = productionCost * 1.3; // Наценка 30%

    query.addBindValue(productionCost);
    query.addBindValue(sellingPrice);

    if (!query.exec()) {
        qDebug() << "Error creating frame order:" << query.lastError().text();
        return false;
    }

    return true;
}

// Создать позицию заказа для набора
bool DatabaseManager::createOrderItem(int orderId, int itemId, const QString &itemType,
                                      int quantity, double unitPrice) {
    QSqlQuery query;
    query.prepare("INSERT INTO order_items (order_id, item_type, item_id, quantity, unit_price, total_price) "
                  "VALUES (?, ?, ?, ?, ?, ?)");
    query.addBindValue(orderId);
    query.addBindValue(itemType);
    query.addBindValue(itemId);
    query.addBindValue(quantity);
    query.addBindValue(unitPrice);
    query.addBindValue(quantity * unitPrice);

    if (!query.exec()) {
        qDebug() << "Error creating order item:" << query.lastError().text();
        return false;
    }

    return true;
}

// Получить заказы для мастера
QSqlQueryModel* DatabaseManager::getMasterOrders() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    QString query = "SELECT o.id, o.order_number, o.order_type, o.status, o.total_amount, "
                    "o.created_at, c.full_name as customer_name, "
                    "fo.width, fo.height, fo.special_instructions "
                    "FROM orders o "
                    "LEFT JOIN customers c ON o.customer_id = c.id "
                    "LEFT JOIN frame_orders fo ON o.id = fo.order_id "
                    "WHERE o.order_type = 'Изготовление рамки' "
                    "ORDER BY o.created_at DESC";
    model->setQuery(query, _database);
    return model;
}

// Обновить статус заказа
bool DatabaseManager::updateOrderStatus(int orderId, const QString &newStatus) {
    QSqlQuery query;
    query.prepare("UPDATE orders SET status = ? WHERE id = ?");
    query.addBindValue(newStatus);
    query.addBindValue(orderId);

    if (!query.exec()) {
        qDebug() << "Error updating order status:" << query.lastError().text();
        return false;
    }
    return true;
}

// Функции для материалов рамок
QSqlQueryModel* DatabaseManager::getFrameMaterialsModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    model->setQuery("SELECT * FROM frame_materials ORDER BY name", _database);
    return model;
}

void DatabaseManager::addFrameMaterial(const QString &name, const QString &type,
                                       double pricePerMeter, double stockQuantity,
                                       const QString &color, double width) {
    QSqlQuery query;
    query.prepare("INSERT INTO frame_materials (name, type, price_per_meter, stock_quantity, "
                  "color, width, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)");
    query.addBindValue(name);
    query.addBindValue(type);
    query.addBindValue(pricePerMeter);
    query.addBindValue(stockQuantity);
    query.addBindValue(color);
    query.addBindValue(width);
    query.addBindValue(currentUserId);

    if (!query.exec()) {
        qDebug() << "Error adding frame material:" << query.lastError().text();
    }
}

void DatabaseManager::updateFrameMaterial(int row, const QString &name, const QString &type,
                                          double pricePerMeter, double stockQuantity,
                                          const QString &color, double width) {
    QSqlQueryModel *model = getFrameMaterialsModel();
    if (!model || row < 0 || row >= model->rowCount()) return;

    int id = model->data(model->index(row, 0)).toInt();

    QSqlQuery query;
    query.prepare("UPDATE frame_materials SET name = ?, type = ?, price_per_meter = ?, "
                  "stock_quantity = ?, color = ?, width = ? WHERE id = ?");
    query.addBindValue(name);
    query.addBindValue(type);
    query.addBindValue(pricePerMeter);
    query.addBindValue(stockQuantity);
    query.addBindValue(color);
    query.addBindValue(width);
    query.addBindValue(id);

    if (!query.exec()) {
        qDebug() << "Error updating frame material:" << query.lastError().text();
    }
}

void DatabaseManager::deleteFrameMaterial(int row) {
    QSqlQueryModel *model = getFrameMaterialsModel();
    if (!model || row < 0 || row >= model->rowCount()) {
        qDebug() << "Invalid row for deletion:" << row;
        return;
    }

    int id = model->data(model->index(row, 0)).toInt();

    QSqlQuery query;
    query.prepare("DELETE FROM frame_materials WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        qDebug() << "Error deleting frame material:" << query.lastError().text();
    } else {
        qDebug() << "Frame material deleted successfully, ID:" << id;
    }
}

QVariantMap DatabaseManager::getFrameMaterialRowData(int row) {
    QVariantMap result;
    QSqlQueryModel *model = getFrameMaterialsModel();

    if (model && row >= 0 && row < model->rowCount()) {
        result["id"] = model->data(model->index(row, 0));
        result["name"] = model->data(model->index(row, 1));
        result["type"] = model->data(model->index(row, 2));
        result["price_per_meter"] = model->data(model->index(row, 3));
        result["stock_quantity"] = model->data(model->index(row, 4));
        result["color"] = model->data(model->index(row, 5));
        result["width"] = model->data(model->index(row, 6));
    }

    return result;
}

// Функции для комплектующей фурнитуры
QSqlQueryModel* DatabaseManager::getComponentFurnitureModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    model->setQuery("SELECT * FROM component_furniture ORDER BY name", _database);
    return model;
}

void DatabaseManager::addComponentFurniture(const QString &name, const QString &type,
                                            double pricePerUnit, int stockQuantity) {
    QSqlQuery query;
    query.prepare("INSERT INTO component_furniture (name, type, price_per_unit, stock_quantity, "
                  "created_by) VALUES (?, ?, ?, ?, ?)");
    query.addBindValue(name);
    query.addBindValue(type);
    query.addBindValue(pricePerUnit);
    query.addBindValue(stockQuantity);
    query.addBindValue(currentUserId);

    if (!query.exec()) {
        qDebug() << "Error adding component furniture:" << query.lastError().text();
    }
}

void DatabaseManager::updateComponentFurniture(int row, const QString &name, const QString &type,
                                               double pricePerUnit, int stockQuantity) {
    QSqlQueryModel *model = getComponentFurnitureModel();
    if (!model || row < 0 || row >= model->rowCount()) return;

    int id = model->data(model->index(row, 0)).toInt();

    QSqlQuery query;
    query.prepare("UPDATE component_furniture SET name = ?, type = ?, price_per_unit = ?, "
                  "stock_quantity = ? WHERE id = ?");
    query.addBindValue(name);
    query.addBindValue(type);
    query.addBindValue(pricePerUnit);
    query.addBindValue(stockQuantity);
    query.addBindValue(id);

    if (!query.exec()) {
        qDebug() << "Error updating component furniture:" << query.lastError().text();
    }
}

void DatabaseManager::deleteComponentFurniture(int row) {
    QSqlQueryModel *model = getComponentFurnitureModel();
    if (!model || row < 0 || row >= model->rowCount()) {
        qDebug() << "Invalid row for deletion:" << row;
        return;
    }

    int id = model->data(model->index(row, 0)).toInt();

    QSqlQuery query;
    query.prepare("DELETE FROM component_furniture WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        qDebug() << "Error deleting component furniture:" << query.lastError().text();
    } else {
        qDebug() << "Component furniture deleted successfully, ID:" << id;
    }
}

QVariantMap DatabaseManager::getComponentFurnitureRowData(int row) {
    QVariantMap result;
    QSqlQueryModel *model = getComponentFurnitureModel();

    if (model && row >= 0 && row < model->rowCount()) {
        result["id"] = model->data(model->index(row, 0));
        result["name"] = model->data(model->index(row, 1));
        result["type"] = model->data(model->index(row, 2));
        result["price_per_unit"] = model->data(model->index(row, 3));
        result["stock_quantity"] = model->data(model->index(row, 4));
    }

    return result;
}

// Получить модель расходной фурнитуры
QSqlQueryModel* DatabaseManager::getConsumableFurnitureModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    model->setQuery("SELECT id, name, type, price_per_unit, stock_quantity, unit FROM consumable_furniture ORDER BY name", _database);
    return model;
}

// Добавить набор для вышивки
void DatabaseManager::addEmbroideryKit(const QString &name, const QString &description, double price, int stockQuantity) {
    QSqlQuery query;
    query.prepare("INSERT INTO embroidery_kits (name, description, price, stock_quantity, created_by) VALUES (?, ?, ?, ?, ?)");
    query.addBindValue(name);
    query.addBindValue(description);
    query.addBindValue(price);
    query.addBindValue(stockQuantity);
    query.addBindValue(currentUserId);

    if (!query.exec()) {
        qDebug() << "Error adding embroidery kit:" << query.lastError().text();
    }
}

// Добавить расходную фурнитуру
void DatabaseManager::addConsumableFurniture(const QString &name, const QString &type, double pricePerUnit, int stockQuantity, const QString &unit) {
    QSqlQuery query;
    query.prepare("INSERT INTO consumable_furniture (name, type, price_per_unit, stock_quantity, unit, created_by) VALUES (?, ?, ?, ?, ?, ?)");
    query.addBindValue(name);
    query.addBindValue(type);
    query.addBindValue(pricePerUnit);
    query.addBindValue(stockQuantity);
    query.addBindValue(unit);
    query.addBindValue(currentUserId);

    if (!query.exec()) {
        qDebug() << "Error adding consumable furniture:" << query.lastError().text();
    }
}

QVariantList DatabaseManager::getOrdersData() {
    QVariantList result;

    QSqlQuery query(_database);
    QString queryStr = "SELECT o.*, c.full_name as customer_name, c.phone as customer_phone, c.email as customer_email "
                       "FROM orders o LEFT JOIN customers c ON o.customer_id = c.id ORDER BY o.created_at DESC";

    qDebug() << "Executing orders query:" << queryStr;

    if (!query.exec(queryStr)) {
        qDebug() << "Error loading orders data:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        QVariantMap rowData;
        QSqlRecord record = query.record();
        for (int i = 0; i < record.count(); ++i) {
            rowData[record.fieldName(i)] = record.value(i);
        }
        result.append(rowData);
        qDebug() << "Order row:" << rowData;
    }

    qDebug() << "Loaded" << result.size() << "orders";
    return result;
}

// Получить данные наборов для вышивки
QVariantList DatabaseManager::getEmbroideryKitsData() {
    QVariantList result;

    QSqlQuery query(_database);
    QString queryStr = "SELECT id, name, description, price, stock_quantity FROM embroidery_kits WHERE is_active = 1 ORDER BY name";

    if (!query.exec(queryStr)) {
        qDebug() << "Error loading embroidery kits data:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        QVariantMap rowData;
        QSqlRecord record = query.record();
        for (int i = 0; i < record.count(); ++i) {
            rowData[record.fieldName(i)] = record.value(i);
        }
        result.append(rowData);
    }

    return result;
}

// Получить данные расходной фурнитуры
QVariantList DatabaseManager::getConsumableFurnitureData() {
    QVariantList result;

    QSqlQuery query(_database);
    QString queryStr = "SELECT id, name, type, price_per_unit, stock_quantity, unit FROM consumable_furniture ORDER BY name";

    if (!query.exec(queryStr)) {
        qDebug() << "Error loading consumable furniture data:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        QVariantMap rowData;
        QSqlRecord record = query.record();
        for (int i = 0; i < record.count(); ++i) {
            rowData[record.fieldName(i)] = record.value(i);
        }
        result.append(rowData);
    }

    return result;
}

// Получить данные покупателей
QVariantList DatabaseManager::getCustomersData() {
    QVariantList result;

    QSqlQuery query(_database);
    QString queryStr = "SELECT id, full_name, phone, email FROM customers ORDER BY full_name";

    if (!query.exec(queryStr)) {
        return result;
    }

    while (query.next()) {
        QVariantMap rowData;
        QSqlRecord record = query.record();
        for (int i = 0; i < record.count(); ++i) {
            rowData[record.fieldName(i)] = record.value(i);
        }
        result.append(rowData);
    }

    return result;
}

// Обновление остатков наборов
void DatabaseManager::updateEmbroideryKitStock(int id, int newQuantity) {
    QSqlQuery query;
    query.prepare("UPDATE embroidery_kits SET stock_quantity = ? WHERE id = ?");
    query.addBindValue(newQuantity);
    query.addBindValue(id);
    query.exec();
}

// Обновление остатков фурнитуры
void DatabaseManager::updateConsumableStock(int id, int newQuantity) {
    QSqlQuery query;
    query.prepare("UPDATE consumable_furniture SET stock_quantity = ? WHERE id = ?");
    query.addBindValue(newQuantity);
    query.addBindValue(id);
    query.exec();
}

// Обновление набора
void DatabaseManager::updateEmbroideryKit(int id, const QString &name, const QString &description,  double price, int stockQuantity) {
    QSqlQuery query;
    query.prepare("UPDATE embroidery_kits SET name = ?, description = ?, price = ?, stock_quantity = ? WHERE id = ?");
    query.addBindValue(name);
    query.addBindValue(description);
    query.addBindValue(price);
    query.addBindValue(stockQuantity);
    query.addBindValue(id);
    query.exec();
}

// Обновление фурнитуры
void DatabaseManager::updateConsumableFurniture(int id, const QString &name, const QString &type, double pricePerUnit, int stockQuantity, const QString &unit) {
    QSqlQuery query;
    query.prepare("UPDATE consumable_furniture SET name = ?, type = ?, price_per_unit = ?, stock_quantity = ?, unit = ? WHERE id = ?");
    query.addBindValue(name);
    query.addBindValue(type);
    query.addBindValue(pricePerUnit);
    query.addBindValue(stockQuantity);
    query.addBindValue(unit);
    query.addBindValue(id);
    query.exec();
}

// Для наборов вышивки
void DatabaseManager::deleteEmbroideryKit(int id) {
    QSqlQuery query;
    query.prepare("DELETE FROM embroidery_kits WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) {
        qDebug() << "Error deleting embroidery kit:" << query.lastError().text();
    }
}

// Для расходной фурнитуры
void DatabaseManager::deleteConsumableFurniture(int id) {
    QSqlQuery query;
    query.prepare("DELETE FROM consumable_furniture WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) {
        qDebug() << "Error deleting consumable furniture:" << query.lastError().text();
    }
}

QVariantList DatabaseManager::getCustomersWithOrdersInPeriod(const QString &startDate, const QString &endDate)
{
    QVariantList result;

    QSqlQuery query;
    query.prepare(
        "SELECT DISTINCT c.id, c.full_name, c.phone, c.email, c.address, "
        "COUNT(o.id) as order_count, SUM(o.total_amount) as total_amount "
        "FROM customers c "
        "INNER JOIN orders o ON c.id = o.customer_id "
        "WHERE o.created_at BETWEEN ? AND ? "
        "GROUP BY c.id, c.full_name, c.phone, c.email, c.address "
        "ORDER BY total_amount DESC"
        );
    query.addBindValue(startDate + " 00:00:00");
    query.addBindValue(endDate + " 23:59:59");

    if (!query.exec()) {
        qDebug() << "Error getting customers with orders in period:" << query.lastError().text();
        return result;
    }

    while (query.next()) {
        QVariantMap customer;
        customer["id"] = query.value("id");
        customer["full_name"] = query.value("full_name");
        customer["phone"] = query.value("phone");
        customer["email"] = query.value("email");
        customer["address"] = query.value("address");
        customer["order_count"] = query.value("order_count");
        customer["total_amount"] = query.value("total_amount");
        result.append(customer);
    }

    return result;
}
