#include "DatabaseManager.h"
#include "logger.h"

// Белый список таблиц для защиты
const QStringList ALLOWED_TABLES = {
    "users", "customers", "frame_materials", "component_furniture",
    "embroidery_kits", "consumable_furniture", "orders",
    "frame_orders", "order_items", "event_logs"
};

DatabaseManager* DatabaseManager::m_instance = nullptr;
QMutex DatabaseManager::m_mutex;

DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent)
{
    // 1. Инициализируем структуру параметров (ВАЖНО!)
    m_dbParams.host = "pg4.sweb.ru";
    m_dbParams.name = "failedmd16";
    m_dbParams.user = "failedmd16";
    m_dbParams.pass = "Bagetworkshop123";
    m_dbParams.port = 5433;
    m_dbParams.options = "requiressl=0;connect_timeout=10";

    if (!initializeDatabase()) {
        Logger::instance().log("Система", "БД", "СБОЙ_ИНИЦИАЛИЗАЦИИ", "Не удалось инициализировать подключение к базе данных");
    }
}

DatabaseManager::~DatabaseManager()
{
    if (_database.isOpen()) {
        _database.close();
    }
}

bool DatabaseManager::initializeDatabase() {
    _database = QSqlDatabase::addDatabase("QPSQL");
    _database.setDatabaseName("failedmd16");
    _database.setHostName("pg4.sweb.ru");
    _database.setPort(5433);
    _database.setUserName("failedmd16");
    _database.setPassword("Bagetworkshop123");
    _database.setConnectOptions("requiressl=0;connect_timeout=10");

    if (!_database.open()) {
        qDebug() << "Ошибка подключения к БД: " << _database.lastError().text();
        return false;
    }

    //createTables();
    return true;
}

DatabaseManager* DatabaseManager::instance() {
    if (!m_instance) {
        m_instance = new DatabaseManager();
    }
    return m_instance;
}

void DatabaseManager::destroyInstance()
{
    QMutexLocker locker(&m_mutex);
    if (m_instance) {
        delete m_instance;
        m_instance = nullptr;
    }
}

void DatabaseManager::createTables() {
    QSqlQuery query;

    // 1. Пользователи
    QString createTableUsersQuery = "CREATE TABLE IF NOT EXISTS users ("
                                    "id SERIAL PRIMARY KEY, "
                                    "login TEXT UNIQUE NOT NULL, "
                                    "password TEXT NOT NULL, "
                                    "role TEXT NOT NULL CHECK(role IN ('Продавец', 'Мастер производства', 'Администратор')), "
                                    "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)";

    if (!query.exec(createTableUsersQuery)) {
        Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ОШИБКА_ТАБЛИЦЫ", "users: " + query.lastError().text());
        return;
    }

    // 2. Логи
    QString createTableEventLogs = "CREATE TABLE IF NOT EXISTS event_logs ("
                                   "id SERIAL PRIMARY KEY, "
                                   "timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                                   "user_login TEXT, "
                                   "category TEXT, "
                                   "action TEXT, "
                                   "description TEXT)";

    if (!query.exec(createTableEventLogs)) {
        qDebug() << "Ошибка создания таблицы логов";
        return;
    }

    // 3. Клиенты
    QString createTableCustomers = "CREATE TABLE IF NOT EXISTS customers ("
                                   "id SERIAL PRIMARY KEY, "
                                   "full_name TEXT NOT NULL, "
                                   "phone TEXT, "
                                   "email TEXT, "
                                   "address TEXT, "
                                   "created_by INTEGER NOT NULL, "
                                   "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                                   "FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT)";

    if (!query.exec(createTableCustomers)) {
        Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ОШИБКА_ТАБЛИЦЫ", "customers: " + query.lastError().text());
        return;
    }

    // 4. Материалы для рамок
    QString createTableFrameMaterials = "CREATE TABLE IF NOT EXISTS frame_materials ("
                                        "id SERIAL PRIMARY KEY, "
                                        "name TEXT NOT NULL, "
                                        "type TEXT NOT NULL, "
                                        "price_per_meter REAL NOT NULL, "
                                        "stock_quantity REAL DEFAULT 0, "
                                        "color TEXT, "
                                        "width REAL, "
                                        "created_by INTEGER NOT NULL, "
                                        "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                                        "FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT)";

    if (!query.exec(createTableFrameMaterials)) {
        Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ОШИБКА_ТАБЛИЦЫ", "frame_materials: " + query.lastError().text());
        return;
    }

    // 5. Комплектующая фурнитура
    QString createTableComponentFurniture = "CREATE TABLE IF NOT EXISTS component_furniture ("
                                            "id SERIAL PRIMARY KEY, "
                                            "name TEXT NOT NULL, "
                                            "type TEXT NOT NULL, "
                                            "price_per_unit REAL NOT NULL, "
                                            "stock_quantity INTEGER DEFAULT 0, "
                                            "created_by INTEGER NOT NULL, "
                                            "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                                            "FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT)";

    if (!query.exec(createTableComponentFurniture)) {
        Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ОШИБКА_ТАБЛИЦЫ", "component_furniture: " + query.lastError().text());
        return;
    }

    // 6. Наборы для вышивания
    QString createTableEmbroideryKits = "CREATE TABLE IF NOT EXISTS embroidery_kits ("
                                        "id SERIAL PRIMARY KEY, "
                                        "name TEXT NOT NULL, "
                                        "description TEXT, "
                                        "price REAL NOT NULL, "
                                        "stock_quantity INTEGER DEFAULT 0, "
                                        "created_by INTEGER NOT NULL, "
                                        "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                                        "is_active BOOLEAN DEFAULT TRUE, "
                                        "FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT)";

    if (!query.exec(createTableEmbroideryKits)) {
        Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ОШИБКА_ТАБЛИЦЫ", "embroidery_kits: " + query.lastError().text());
        return;
    }

    // 7. Расходная фурнитура
    QString createTableConsumableFurniture = "CREATE TABLE IF NOT EXISTS consumable_furniture ("
                                             "id SERIAL PRIMARY KEY, "
                                             "name TEXT NOT NULL, "
                                             "type TEXT NOT NULL, "
                                             "price_per_unit REAL NOT NULL, "
                                             "stock_quantity INTEGER DEFAULT 0, "
                                             "unit TEXT NOT NULL, "
                                             "created_by INTEGER NOT NULL, "
                                             "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                                             "FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT)";

    if (!query.exec(createTableConsumableFurniture)) {
        Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ОШИБКА_ТАБЛИЦЫ", "consumable_furniture: " + query.lastError().text());
        return;
    }

    // 8. Заказы
    QString createTableOrders = "CREATE TABLE IF NOT EXISTS orders ("
                                "id SERIAL PRIMARY KEY, "
                                "order_number TEXT UNIQUE NOT NULL, "
                                "customer_id INTEGER NOT NULL, "
                                "order_type TEXT NOT NULL CHECK(order_type IN ('Изготовление рамки', 'Продажа набора')), "
                                "total_amount REAL NOT NULL, "
                                "status TEXT NOT NULL CHECK(status IN ('Новый', 'В работе', 'Готов', 'Завершён', 'Отменён')), "
                                "notes TEXT, "
                                "created_by INTEGER NOT NULL, "
                                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, "
                                "completed_at TIMESTAMP, "
                                "FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT, "
                                "FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT)";

    if (!query.exec(createTableOrders)) {
        Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ОШИБКА_ТАБЛИЦЫ", "orders: " + query.lastError().text());
        return;
    }

    // 9. Спецификация рамок в заказах
    QString createTableFrameOrders = "CREATE TABLE IF NOT EXISTS frame_orders ("
                                     "id SERIAL PRIMARY KEY, "
                                     "order_id INTEGER NOT NULL, "
                                     "width REAL NOT NULL, "
                                     "height REAL NOT NULL, "
                                     "frame_material_id INTEGER NOT NULL, "
                                     "component_furniture_id INTEGER NOT NULL, "
                                     "master_id INTEGER, "
                                     "special_instructions TEXT, "
                                     "production_cost REAL NOT NULL, "
                                     "selling_price REAL NOT NULL, "
                                     "FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE, "
                                     "FOREIGN KEY (frame_material_id) REFERENCES frame_materials(id) ON DELETE RESTRICT, "
                                     "FOREIGN KEY (component_furniture_id) REFERENCES component_furniture(id) ON DELETE RESTRICT, "
                                     "FOREIGN KEY (master_id) REFERENCES users(id) ON DELETE SET NULL)";

    if (!query.exec(createTableFrameOrders)) {
        Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ОШИБКА_ТАБЛИЦЫ", "frame_orders: " + query.lastError().text());
        return;
    }

    // 10. Товары в заказе
    QString createTableOrderItems = "CREATE TABLE IF NOT EXISTS order_items ("
                                    "id SERIAL PRIMARY KEY, "
                                    "order_id INTEGER NOT NULL, "
                                    "embroidery_kit_id INTEGER, "
                                    "consumable_furniture_id INTEGER, "
                                    "item_name TEXT NOT NULL, "
                                    "quantity INTEGER NOT NULL, "
                                    "unit_price REAL NOT NULL, "
                                    "total_price REAL NOT NULL, "
                                    "CHECK ( NOT (embroidery_kit_id IS NOT NULL AND consumable_furniture_id IS NOT NULL) ), "
                                    "FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE, "
                                    "FOREIGN KEY (embroidery_kit_id) REFERENCES embroidery_kits(id) ON DELETE SET NULL, "
                                    "FOREIGN KEY (consumable_furniture_id) REFERENCES consumable_furniture(id) ON DELETE SET NULL)";

    if (!query.exec(createTableOrderItems)) {
        Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ОШИБКА_ТАБЛИЦЫ", "order_items: " + query.lastError().text());
        return;
    }

    // 11. Индексы
    QStringList indexQueries;
    indexQueries << "CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id)"
                 << "CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at)"
                 << "CREATE INDEX IF NOT EXISTS idx_frame_orders_order_id ON frame_orders(order_id)"
                 << "CREATE INDEX IF NOT EXISTS idx_frame_orders_master_id ON frame_orders(master_id)"
                 << "CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id)"
                 << "CREATE INDEX IF NOT EXISTS idx_customers_full_name ON customers(full_name)"
                 << "CREATE INDEX IF NOT EXISTS idx_event_logs_timestamp ON event_logs(timestamp)";

    for(const QString &idxQ : indexQueries) {
        if(!query.exec(idxQ)) {
            Logger::instance().log("Система", "ИНИЦИАЛИЗАЦИЯ", "ПРЕДУПРЕЖДЕНИЕ_ИНДЕКС", query.lastError().text());
        }
    }

    Logger::instance().log("Система", "ПРИЛОЖЕНИЕ", "ЗАПУСК", "Таблицы инициализированы успешно");
}

bool DatabaseManager::loginUser(const QString &login, const QString &password) {
    if (!_database.isOpen()) return false;

    QString hashedPassword = hashPassword(password);

    QSqlQuery query;
    query.prepare("SELECT id, role, password FROM users WHERE login = ?");
    query.addBindValue(login);

    if (!query.exec()) {
        Logger::instance().log(login, "АВТОРИЗАЦИЯ", "ОШИБКА_SQL", query.lastError().text());
        return false;
    }

    if (query.next()) {
        if (query.value(2).toString() == hashedPassword) {
            currentUserId = query.value(0).toInt();
            currentUserRole = query.value(1).toString();
            Logger::instance().log(login, "АВТОРИЗАЦИЯ", "ВХОД_УСПЕШЕН", "Роль: " + currentUserRole);
            return true;
        } else {
            Logger::instance().log(login, "АВТОРИЗАЦИЯ", "ВХОД_ПРОВАЛЕН", "Неверный пароль");
        }
    } else {
        Logger::instance().log(login, "АВТОРИЗАЦИЯ", "ВХОД_ПРОВАЛЕН", "Пользователь не найден");
    }
    return false;
}

QString DatabaseManager::hashPassword(const QString &password) {
    QByteArray hash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256);
    return QString(hash.toHex());
}

bool DatabaseManager::validateLogin(const QString &login)
{
    if (login.length() < 3 || login.length() > 20) return false;
    QRegularExpression regex("^[a-zA-Z0-9_]+$");
    return regex.match(login).hasMatch();
}

bool DatabaseManager::validatePassword(const QString &password)
{
    if (password.length() < 6) return false;
    QRegularExpression digitRegex("\\d");
    if (!digitRegex.match(password).hasMatch()) return false;
    QRegularExpression letterRegex("[a-zA-Z]");
    return letterRegex.match(password).hasMatch();
}

bool DatabaseManager::registrationUser(const QString &login, const QString &password, const QString &role) {
    if (!_database.isOpen()) return false;

    if (!validateLogin(login) || !validatePassword(password)) {
        Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ОШИБКА_РЕГИСТРАЦИИ", "Некорректный логин или пароль для: " + login);
        return false;
    }

    QSqlQuery query;
    query.prepare("SELECT id FROM users WHERE login = ?");
    query.addBindValue(login);

    if (!query.exec()) {
        Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ОШИБКА_SQL", query.lastError().text());
        return false;
    }

    if (query.next()) {
        Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ОШИБКА_РЕГИСТРАЦИИ", "Пользователь уже существует: " + login);
        return false;
    }

    QString hashedPassword = hashPassword(password);

    query.prepare("INSERT INTO users (login, password, role) VALUES (?, ?, ?)");
    query.addBindValue(login);
    query.addBindValue(hashedPassword);
    query.addBindValue(role);

    if (!query.exec()) {
        Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ОШИБКА_СОЗДАНИЯ", query.lastError().text());
        return false;
    }

    Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ПОЛЬЗОВАТЕЛЬ_СОЗДАН", "Логин: " + login + ", Роль: " + role);
    return true;
}

bool DatabaseManager::updateUserPassword(const QString &login, const QString &newPassword) {
    if (!_database.isOpen()) return false;

    if (!validatePassword(newPassword)) return false;

    QString hashedPassword = hashPassword(newPassword);

    QSqlQuery query;
    query.prepare("UPDATE users SET password = ? WHERE login = ?");
    query.addBindValue(hashedPassword);
    query.addBindValue(login);

    if (!query.exec()) {
        Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "СМЕНА_ПАРОЛЯ_ОШИБКА", query.lastError().text());
        return false;
    }

    if (query.numRowsAffected() > 0) {
        Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ПАРОЛЬ_ОБНОВЛЕН", "Пользователь: " + login);
        return true;
    }
    return false;
}

bool DatabaseManager::deleteUser(const QString &login) {
    if (!_database.isOpen()) return false;

    QSqlQuery query;
    query.prepare("DELETE FROM users WHERE login = ?");
    query.addBindValue(login);

    if (!query.exec()) {
        Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ОШИБКА_УДАЛЕНИЯ", query.lastError().text());
        return false;
    }

    if (query.numRowsAffected() > 0) {
        Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ПОЛЬЗОВАТЕЛЬ_УДАЛЕН", login);
        return true;
    } else {
        Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ОШИБКА_УДАЛЕНИЯ", "Пользователь не найден: " + login);
        return false;
    }
}

int DatabaseManager::getCurrentUserID() {
    return currentUserId;
}

QString DatabaseManager::getCurrentUserRole() const {
    return currentUserRole;
}

QSqlQueryModel* DatabaseManager::getTableModel(const QString &name) {
    QSqlQueryModel *model = new QSqlQueryModel(this);

    if (!ALLOWED_TABLES.contains(name)) {
        return model;
    }

    QString queryStr = "SELECT * FROM " + name;

    if (name == "embroidery_kits" || name == "consumable_furniture" || name == "frame_materials" || name == "component_furniture") {
        queryStr += " ORDER BY id DESC";
    }

    model->setQuery(queryStr, _database);
    if (model->lastError().isValid()) {
        Logger::instance().log("Система", "UI", "ОШИБКА_МОДЕЛИ", name + ": " + model->lastError().text());
    }
    return model;
}

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
    }
    if (model) delete model;
    return result;
}

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
        Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "ОШИБКА_ДОБАВЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "ДОБАВЛЕН", name);
    }
}

void DatabaseManager::updateCustomer(int row, const QString &name, const QString &phone, const QString &email, const QString &address)
{
    QSqlQueryModel *model = getTableModel("customers");
    if (!model) return;

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
        Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "ОШИБКА_ОБНОВЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "ОБНОВЛЕН", "ID: " + QString::number(id));
    }
    delete model;
}

void DatabaseManager::deleteCustomer(int row)
{
    QSqlQueryModel *model = getTableModel("customers");
    if (!model) return;

    QSqlRecord record = model->record(row);
    int id = record.value("id").toInt();

    QSqlQuery query;
    query.prepare("DELETE FROM customers WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "ОШИБКА_УДАЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "УДАЛЕН", "ID: " + QString::number(id));
    }
    delete model;
}

int DatabaseManager::getRowCount(const QString &table)
{
    if (!ALLOWED_TABLES.contains(table)) return 0;
    QSqlQuery query;
    query.prepare("SELECT COUNT(*) FROM " + table);
    if (query.exec() && query.next())
        return query.value(0).toInt();
    return 0;
}

QVariantList DatabaseManager::getCustomerOrders(int customerId)
{
    QVariantList orders;
    QSqlQuery query;
    query.prepare("SELECT * FROM orders WHERE customer_id = ? ORDER BY created_at DESC");
    query.addBindValue(customerId);

    if (!query.exec()) {
        Logger::instance().log("Система", "ДАННЫЕ", "ОШИБКА_ЗАГРУЗКИ", query.lastError().text());
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
    return orders;
}

QSqlQueryModel* DatabaseManager::getCustomersModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    model->setQuery("SELECT id, full_name, phone, email FROM customers ORDER BY full_name", _database);
    return model;
}

QSqlQueryModel* DatabaseManager::getEmbroideryKitsModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    model->setQuery("SELECT id, name, price FROM embroidery_kits WHERE is_active = 1 ORDER BY name", _database);
    return model;
}

int DatabaseManager::createOrder(const QString &orderNumber, int customerId, const QString &orderType, double totalAmount, const QString &status, const QString &notes) {
    QSqlQuery query;
    query.prepare("INSERT INTO orders (order_number, customer_id, order_type, total_amount, status, notes, created_by) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id");
    query.addBindValue(orderNumber);
    query.addBindValue(customerId);
    query.addBindValue(orderType);
    query.addBindValue(totalAmount);
    query.addBindValue(status);
    query.addBindValue(notes);
    query.addBindValue(currentUserId);

    if (query.exec() && query.next()) {
        int id = query.value(0).toInt();
        Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "СОЗДАН", "ID: " + QString::number(id));
        return id;
    }
    Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "ОШИБКА_СОЗДАНИЯ", query.lastError().text());
    return -1;
}

void DatabaseManager::updateOrder(int id, const QString &status, double totalAmount, const QString &notes)
{
    QSqlQuery query;
    QString sql = "UPDATE orders SET status = ?, total_amount = ?, notes = ?";
    if (status == "Завершён") {
        sql += ", completed_at = CURRENT_TIMESTAMP";
    }
    sql += " WHERE id = ?";

    query.prepare(sql);
    query.addBindValue(status);
    query.addBindValue(totalAmount);
    query.addBindValue(notes);
    query.addBindValue(id);

    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "ОШИБКА_ОБНОВЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "ОБНОВЛЕН", QString::number(id));
    }
}

void DatabaseManager::deleteOrder(int id)
{
    QSqlQuery query;
    query.prepare("DELETE FROM orders WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "ОШИБКА_УДАЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "УДАЛЕН", QString::number(id));
    }
}

bool DatabaseManager::createFrameOrder(int orderId, double width, double height,
                                       int frameMaterialId, int componentFurnitureId,
                                       int masterId, const QString &specialInstructions) {
    QSqlQuery query;

    // Расчет цены
    QSqlQuery matQuery;
    matQuery.prepare("SELECT price_per_meter FROM frame_materials WHERE id = ?");
    matQuery.addBindValue(frameMaterialId);
    double pricePerMeter = 0.0;
    if (matQuery.exec() && matQuery.next()) pricePerMeter = matQuery.value(0).toDouble();

    double metersNeeded = ((width + height) * 2 / 100.0) * 1.15;
    double productionCost = (metersNeeded * pricePerMeter) + 500.0;
    double sellingPrice = productionCost * 2.0;

    // Обновление суммы заказа
    QSqlQuery updateOrder;
    updateOrder.prepare("UPDATE orders SET total_amount = ? WHERE id = ?");
    updateOrder.addBindValue(sellingPrice);
    updateOrder.addBindValue(orderId);
    updateOrder.exec();

    query.prepare("INSERT INTO frame_orders (order_id, width, height, frame_material_id, "
                  "component_furniture_id, master_id, special_instructions, production_cost, selling_price) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    query.addBindValue(orderId);
    query.addBindValue(width);
    query.addBindValue(height);
    query.addBindValue(frameMaterialId);
    query.addBindValue(componentFurnitureId);

    if (masterId > 0) query.addBindValue(masterId);
    else query.addBindValue(QVariant(QVariant::Int));

    query.addBindValue(specialInstructions);
    query.addBindValue(productionCost);
    query.addBindValue(sellingPrice);

    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "ОШИБКА_РАМКИ", query.lastError().text());
        return false;
    }

    // Списание
    QSqlQuery updateStock;
    updateStock.prepare("UPDATE frame_materials SET stock_quantity = stock_quantity - ? WHERE id = ?");
    updateStock.addBindValue(metersNeeded);
    updateStock.addBindValue(frameMaterialId);
    updateStock.exec();

    Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "РАМКА_ОФОРМЛЕНА", "Заказ: " + QString::number(orderId));
    return true;
}

int DatabaseManager::getRetailCustomerId() {
    QSqlQuery query;
    if (query.exec("SELECT id FROM customers WHERE full_name = 'Розничный покупатель'") && query.next()) {
        return query.value(0).toInt();
    }
    query.prepare("INSERT INTO customers (full_name, phone, email, address, created_by) "
                  "VALUES ('Розничный покупатель', '-', '-', 'Магазин', ?) RETURNING id");
    query.addBindValue(currentUserId);
    if (query.exec() && query.next()) return query.value(0).toInt();

    return -1;
}

QSqlQueryModel* DatabaseManager::getMastersModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    model->setQuery("SELECT id, login FROM users WHERE role = 'Мастер производства' ORDER BY login", _database);
    return model;
}

bool DatabaseManager::createOrderItem(int orderId, int itemId, const QString &itemType, const QString &itemName, int quantity, double unitPrice) {
    QSqlQuery query;

    if (itemType == "Готовый набор") {
        query.prepare("INSERT INTO order_items (order_id, embroidery_kit_id, item_name, quantity, unit_price, total_price) "
                      "VALUES (?, ?, ?, ?, ?, ?)");
    } else {
        query.prepare("INSERT INTO order_items (order_id, consumable_furniture_id, item_name, quantity, unit_price, total_price) "
                      "VALUES (?, ?, ?, ?, ?, ?)");
    }

    query.addBindValue(orderId);
    query.addBindValue(itemId);
    query.addBindValue(itemName);
    query.addBindValue(quantity);
    query.addBindValue(unitPrice);
    query.addBindValue(quantity * unitPrice);

    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "ОШИБКА_ПОЗИЦИИ", query.lastError().text());
        return false;
    }

    QSqlQuery stockQuery;
    if (itemType == "Готовый набор") {
        stockQuery.prepare("UPDATE embroidery_kits SET stock_quantity = stock_quantity - ? WHERE id = ?");
    } else {
        stockQuery.prepare("UPDATE consumable_furniture SET stock_quantity = stock_quantity - ? WHERE id = ?");
    }
    stockQuery.addBindValue(quantity);
    stockQuery.addBindValue(itemId);
    stockQuery.exec();

    return true;
}

bool DatabaseManager::updateOrderStatus(int orderId, const QString &newStatus) {
    QSqlQuery query;
    if (newStatus == "Завершён") {
        query.prepare("UPDATE orders SET status = ?, completed_at = CURRENT_TIMESTAMP WHERE id = ?");
    } else {
        query.prepare("UPDATE orders SET status = ? WHERE id = ?");
    }
    query.addBindValue(newStatus);
    query.addBindValue(orderId);

    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "ОШИБКА_СТАТУСА", query.lastError().text());
        return false;
    }
    Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "СТАТУС_ОБНОВЛЕН", "ID: " + QString::number(orderId));
    return true;
}

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
        Logger::instance().log(QString::number(currentUserId), "МАТЕРИАЛЫ", "ОШИБКА_ДОБАВЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "МАТЕРИАЛЫ", "ДОБАВЛЕН", name);
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
        Logger::instance().log(QString::number(currentUserId), "МАТЕРИАЛЫ", "ОШИБКА_ОБНОВЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "МАТЕРИАЛЫ", "ОБНОВЛЕН", QString::number(id));
    }
    delete model;
}

void DatabaseManager::deleteFrameMaterial(int row) {
    QSqlQueryModel *model = getFrameMaterialsModel();
    if (!model || row < 0 || row >= model->rowCount()) return;
    int id = model->data(model->index(row, 0)).toInt();

    QSqlQuery query;
    query.prepare("DELETE FROM frame_materials WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "МАТЕРИАЛЫ", "ОШИБКА_УДАЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "МАТЕРИАЛЫ", "УДАЛЕН", QString::number(id));
    }
    delete model;
}

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
        Logger::instance().log(QString::number(currentUserId), "ФУРНИТУРА", "ОШИБКА_ДОБАВЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "ФУРНИТУРА", "ДОБАВЛЕНА", name);
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
        Logger::instance().log(QString::number(currentUserId), "ФУРНИТУРА", "ОШИБКА_ОБНОВЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "ФУРНИТУРА", "ОБНОВЛЕНА", QString::number(id));
    }
    delete model;
}

void DatabaseManager::deleteComponentFurniture(int row) {
    QSqlQueryModel *model = getComponentFurnitureModel();
    if (!model || row < 0 || row >= model->rowCount()) return;
    int id = model->data(model->index(row, 0)).toInt();

    QSqlQuery query;
    query.prepare("DELETE FROM component_furniture WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "ФУРНИТУРА", "ОШИБКА_УДАЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "ФУРНИТУРА", "УДАЛЕНА", QString::number(id));
    }
    delete model;
}

void DatabaseManager::addEmbroideryKit(const QString &name, const QString &description, double price, int stockQuantity) {
    QSqlQuery query;
    query.prepare("INSERT INTO embroidery_kits (name, description, price, stock_quantity, created_by) VALUES (?, ?, ?, ?, ?)");
    query.addBindValue(name);
    query.addBindValue(description);
    query.addBindValue(price);
    query.addBindValue(stockQuantity);
    query.addBindValue(currentUserId);

    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "ВЫШИВКА", "ОШИБКА_ДОБАВЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "ВЫШИВКА", "ДОБАВЛЕНА", name);
    }
}

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
        Logger::instance().log(QString::number(currentUserId), "РАСХОДНИКИ", "ОШИБКА_ДОБАВЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "РАСХОДНИКИ", "ДОБАВЛЕНЫ", name);
    }
}

QVariantList DatabaseManager::getOrdersData() {
    QVariantList result;
    QSqlQuery query(_database);

    query.setForwardOnly(true);
    QString queryStr = "SELECT "
                       "o.id, o.order_number, o.order_type, o.status, o.total_amount, o.created_at, o.notes, "
                       "c.full_name as customer_name, c.phone as customer_phone, "
                       "u.login as created_by_user "
                       "FROM orders o "
                       "LEFT JOIN customers c ON o.customer_id = c.id "
                       "LEFT JOIN users u ON o.created_by = u.id "
                       "ORDER BY o.created_at DESC";

    if (!query.exec(queryStr)) {
        Logger::instance().log("Система", "ДАННЫЕ", "ОШИБКА_ЗАКАЗОВ", query.lastError().text());
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

void DatabaseManager::updateEmbroideryKitStock(int id, int newQuantity) {
    QSqlQuery query;
    query.prepare("UPDATE embroidery_kits SET stock_quantity = ? WHERE id = ?");
    query.addBindValue(newQuantity);
    query.addBindValue(id);
    query.exec();
}

void DatabaseManager::updateConsumableStock(int id, int newQuantity) {
    QSqlQuery query;
    query.prepare("UPDATE consumable_furniture SET stock_quantity = ? WHERE id = ?");
    query.addBindValue(newQuantity);
    query.addBindValue(id);
    query.exec();
}

void DatabaseManager::updateEmbroideryKit(int id, const QString &name, const QString &description,  double price, int stockQuantity) {
    QSqlQuery query;
    query.prepare("UPDATE embroidery_kits SET name = ?, description = ?, price = ?, stock_quantity = ? WHERE id = ?");
    query.addBindValue(name);
    query.addBindValue(description);
    query.addBindValue(price);
    query.addBindValue(stockQuantity);
    query.addBindValue(id);
    if(query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "ВЫШИВКА", "ОБНОВЛЕНА", QString::number(id));
    }
}

void DatabaseManager::updateConsumableFurniture(int id, const QString &name, const QString &type, double pricePerUnit, int stockQuantity, const QString &unit) {
    QSqlQuery query;
    query.prepare("UPDATE consumable_furniture SET name = ?, type = ?, price_per_unit = ?, stock_quantity = ?, unit = ? WHERE id = ?");
    query.addBindValue(name);
    query.addBindValue(type);
    query.addBindValue(pricePerUnit);
    query.addBindValue(stockQuantity);
    query.addBindValue(unit);
    query.addBindValue(id);
    if(query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "РАСХОДНИКИ", "ОБНОВЛЕНЫ", QString::number(id));
    }
}

void DatabaseManager::deleteEmbroideryKit(int id) {
    QSqlQuery query;
    query.prepare("DELETE FROM embroidery_kits WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "ВЫШИВКА", "ОШИБКА_УДАЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "ВЫШИВКА", "УДАЛЕНА", QString::number(id));
    }
}

void DatabaseManager::deleteConsumableFurniture(int id) {
    QSqlQuery query;
    query.prepare("DELETE FROM consumable_furniture WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) {
        Logger::instance().log(QString::number(currentUserId), "РАСХОДНИКИ", "ОШИБКА_УДАЛЕНИЯ", query.lastError().text());
    } else {
        Logger::instance().log(QString::number(currentUserId), "РАСХОДНИКИ", "УДАЛЕНЫ", QString::number(id));
    }
}


QVariantList DatabaseManager::getCustomersWithOrdersInPeriod(const QString &startDate, const QString &endDate)
{
    QVariantList result;
    QSqlQuery query;
    query.prepare(
        "SELECT c.id, c.full_name, c.phone, c.email, c.address, "
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
        Logger::instance().log("Система", "ОТЧЕТ", "ОШИБКА", query.lastError().text());
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

int DatabaseManager::getLastInsertedOrderId() {
    QSqlQuery query;
    if (query.exec("SELECT lastval()") && query.next()) {
        return query.value(0).toInt();
    }
    return -1;
}

QVariantList DatabaseManager::getMasterOrdersData() {
    QVariantList result;
    QSqlQuery query(_database);
    query.setForwardOnly(true);

    QString queryStr = "SELECT "
                       "o.id, o.order_number, o.order_type, o.status, o.total_amount, o.created_at, "
                       "c.full_name as customer_name, c.phone as customer_phone, "
                       "fo.width, fo.height, fo.special_instructions, "
                       "fm.name as material_name, fm.color as material_color "
                       "FROM orders o "
                       "LEFT JOIN customers c ON o.customer_id = c.id "
                       "LEFT JOIN frame_orders fo ON o.id = fo.order_id "
                       "LEFT JOIN frame_materials fm ON fo.frame_material_id = fm.id "
                       "WHERE o.order_type = 'Изготовление рамки' "
                       "AND (fo.master_id = ? OR fo.master_id IS NULL) "
                       "ORDER BY o.created_at DESC";

    query.prepare(queryStr);
    query.addBindValue(currentUserId);

    if (!query.exec()) {
        Logger::instance().log("Система", "МАСТЕР", "ОШИБКА_ДАННЫХ", query.lastError().text());
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

bool DatabaseManager::hasAdminAccount() {
    if (!_database.isOpen()) return false;

    QSqlQuery query;
    if (query.exec("SELECT COUNT(*) FROM users WHERE role = 'Администратор'")) {
        if (query.next()) {
            return query.value(0).toInt() > 0;
        }
    }
    return false;
}

bool DatabaseManager::createFirstAdmin(const QString &login, const QString &password) {
    if (hasAdminAccount()) {
        return false;
    }

    if (!validateLogin(login) || !validatePassword(password)) {
        Logger::instance().log("Система", "АВТОРИЗАЦИЯ", "СОЗДАНИЕ_АДМИНА", "Некорректный логин/пароль");
        return false;
    }

    QString hashedPassword = hashPassword(password);

    QSqlQuery query;
    query.prepare("INSERT INTO users (login, password, role) VALUES (?, ?, 'Администратор')");
    query.addBindValue(login);
    query.addBindValue(hashedPassword);

    if (!query.exec()) {
        Logger::instance().log("Система", "АВТОРИЗАЦИЯ", "ОШИБКА_АДМИНА", query.lastError().text());
        return false;
    }

    Logger::instance().log("Система", "АВТОРИЗАЦИЯ", "АДМИН_СОЗДАН", "Первый администратор зарегистрирован");
    return true;
}

void DatabaseManager::fetchLogs() {
    // Запускаем лямбда-функцию в фоновом потоке
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;

        if (!db.isOpen()) {
            emit logsLoaded(result); // Отправляем пустой список при ошибке
            return;
        }

        QSqlQuery query(db);
        // Сортируем от новых к старым, лимит 1000 для быстродействия
        query.prepare("SELECT * FROM event_logs ORDER BY timestamp DESC LIMIT 1000");

        if (query.exec()) {
            while (query.next()) {
                QVariantMap row;
                QSqlRecord record = query.record();
                // Преобразуем SQL запись в JSON-подобный объект (Map)
                for (int i = 0; i < record.count(); ++i) {
                    row[record.fieldName(i)] = record.value(i);
                }
                result.append(row);
            }
        } else {
            Logger::instance().log("Система", "ДАННЫЕ", "ОШИБКА_ЛОГОВ", query.lastError().text());
        }

        // Отправляем готовые данные в QML (в главный поток)
        emit logsLoaded(result);
    });
}

void DatabaseManager::fetchLogsCount() {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QSqlQuery query(db);
        int count = 0;
        if (query.exec("SELECT COUNT(*) FROM event_logs") && query.next()) {
            count = query.value(0).toInt();
        }
        emit logsCountLoaded(count);
    });
}

QSqlDatabase DatabaseManager::getThreadLocalConnection() {
    // Создаем имя соединения, уникальное для текущего потока
    QString connectionName = "ThreadConn_" + QString::number((quint64)QThread::currentThread(), 16);

    if (QSqlDatabase::contains(connectionName)) {
        QSqlDatabase db = QSqlDatabase::database(connectionName);
        if (!db.isOpen()) db.open();
        return db;
    }

    // Создаем новое соединение, используя сохраненные параметры
    QSqlDatabase db = QSqlDatabase::addDatabase("QPSQL", connectionName);
    db.setDatabaseName(m_dbParams.name);
    db.setHostName(m_dbParams.host);
    db.setPort(m_dbParams.port);
    db.setUserName(m_dbParams.user);
    db.setPassword(m_dbParams.pass);
    db.setConnectOptions(m_dbParams.options);

    if (!db.open()) {
        qDebug() << "Thread connection error:" << db.lastError().text();
    }
    return db;
}

void DatabaseManager::fetchLogsByPeriod(const QString &dateFrom, const QString &dateTo) {
    // Запускаем в фоновом потоке
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;

        if (!db.isOpen()) {
            emit logsLoaded(result);
            return;
        }

        // Парсим даты из строк (формат dd.MM.yyyy, как в QML)
        QDate startDate = QDate::fromString(dateFrom, "dd.MM.yyyy");
        QDate endDate = QDate::fromString(dateTo, "dd.MM.yyyy");

        // Проверка на валидность (на всякий случай, хотя QML проверяет)
        if (!startDate.isValid() || !endDate.isValid()) {
            // Если даты некорректны, можно вернуть пустой список или все логи
            // В данном случае вернем пустой список
            emit logsLoaded(result);
            return;
        }

        // Преобразуем в QDateTime для захвата всего времени суток
        // С 00:00:00 первого дня
        QDateTime startDt = startDate.startOfDay();
        // До 23:59:59 последнего дня
        QDateTime endDt = endDate.endOfDay();

        QSqlQuery query(db);
        query.prepare("SELECT * FROM event_logs "
                      "WHERE timestamp >= ? AND timestamp <= ? "
                      "ORDER BY timestamp DESC");

        query.addBindValue(startDt);
        query.addBindValue(endDt);

        if (query.exec()) {
            while (query.next()) {
                QVariantMap row;
                QSqlRecord record = query.record();
                for (int i = 0; i < record.count(); ++i) {
                    row[record.fieldName(i)] = record.value(i);
                }
                result.append(row);
            }
        } else {
            Logger::instance().log("Система", "ДАННЫЕ", "ОШИБКА_ФИЛЬТРА", query.lastError().text());
        }

        // Эмитим тот же сигнал, что и при обычной загрузке.
        // QML обновит модель logListModel этими данными.
        emit logsLoaded(result);
    });
}

void DatabaseManager::registerUserAsync(const QString &login, const QString &password, const QString &role)
{
    QtConcurrent::run([=]() {
        // 1. Проверки без БД (быстрые)
        if (!validateLogin(login) || !validatePassword(password)) {
            emit userOperationResult(false, "Некорректный логин или пароль (Логин: 3-20 симв., Пароль: мин 6, цифры+буквы)");
            Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ОШИБКА_РЕГИСТРАЦИИ", "Валидация не прошла: " + login);
            return;
        }

        // 2. Получаем соединение для потока
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit userOperationResult(false, "Ошибка соединения с базой данных");
            return;
        }

        QSqlQuery query(db);

        // 3. Проверяем существование
        query.prepare("SELECT id FROM users WHERE login = ?");
        query.addBindValue(login);

        if (!query.exec()) {
            emit userOperationResult(false, "Ошибка SQL при проверке: " + query.lastError().text());
            return;
        }

        if (query.next()) {
            emit userOperationResult(false, "Пользователь с таким логином уже существует");
            return;
        }

        // 4. Создаем
        QString hashedPassword = hashPassword(password);
        query.prepare("INSERT INTO users (login, password, role) VALUES (?, ?, ?)");
        query.addBindValue(login);
        query.addBindValue(hashedPassword);
        query.addBindValue(role);

        if (!query.exec()) {
            emit userOperationResult(false, "Ошибка создания: " + query.lastError().text());
            Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ОШИБКА_СОЗДАНИЯ", query.lastError().text());
        } else {
            emit userOperationResult(true, "Пользователь успешно создан");
            Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ПОЛЬЗОВАТЕЛЬ_СОЗДАН", "Логин: " + login);
        }
    });
}

void DatabaseManager::updateUserPasswordAsync(const QString &login, const QString &newPassword)
{
    QtConcurrent::run([=]() {
        if (!validatePassword(newPassword)) {
            emit userOperationResult(false, "Пароль слишком простой (мин 6 символов, цифры и буквы)");
            return;
        }

        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit userOperationResult(false, "Нет соединения с БД");
            return;
        }

        QString hashedPassword = hashPassword(newPassword);

        QSqlQuery query(db);
        query.prepare("UPDATE users SET password = ? WHERE login = ?");
        query.addBindValue(hashedPassword);
        query.addBindValue(login);

        if (!query.exec()) {
            emit userOperationResult(false, "Ошибка SQL: " + query.lastError().text());
        } else {
            if (query.numRowsAffected() > 0) {
                emit userOperationResult(true, "Пароль успешно изменен");
                Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ПАРОЛЬ_ОБНОВЛЕН", "Пользователь: " + login);
            } else {
                emit userOperationResult(false, "Пользователь с таким логином не найден");
            }
        }
    });
}

void DatabaseManager::deleteUserAsync(const QString &login)
{
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit userOperationResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        query.prepare("DELETE FROM users WHERE login = ?");
        query.addBindValue(login);

        if (!query.exec()) {
            emit userOperationResult(false, "Ошибка удалени: " + query.lastError().text());
        } else {
            if (query.numRowsAffected() > 0) {
                emit userOperationResult(true, "Пользователь удален");
                Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ПОЛЬЗОВАТЕЛЬ_УДАЛЕН", login);
            } else {
                emit userOperationResult(false, "Пользователь не найден");
            }
        }
    });
}


// 1. ЗАГРУЗКА СПИСКА КЛИЕНТОВ
void DatabaseManager::fetchCustomers() {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;
        if (!db.isOpen()) { emit customersLoaded(result); return; }

        QSqlQuery query(db);
        // Сортируем по ID или имени
        query.prepare("SELECT * FROM customers ORDER BY id DESC");

        if (query.exec()) {
            while (query.next()) {
                QVariantMap row;
                QSqlRecord record = query.record();
                for (int i = 0; i < record.count(); ++i) {
                    row[record.fieldName(i)] = record.value(i);
                }
                result.append(row);
            }
        }
        emit customersLoaded(result);
    });
}

// 2. ДОБАВЛЕНИЕ КЛИЕНТА
void DatabaseManager::addCustomerAsync(const QString &name, const QString &phone, const QString &email, const QString &address) {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) { emit customerOperationResult(false, "Нет соединения с БД"); return; }

        QSqlQuery query(db);
        query.prepare("INSERT INTO customers (full_name, phone, email, address, created_by) VALUES (?, ?, ?, ?, ?)");
        query.addBindValue(name);
        query.addBindValue(phone);
        query.addBindValue(email);
        query.addBindValue(address);
        query.addBindValue(currentUserId); // ID текущего юзера

        if (!query.exec()) {
            emit customerOperationResult(false, "Ошибка добавления: " + query.lastError().text());
        } else {
            emit customerOperationResult(true, "Покупатель успешно добавлен");
            Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "ДОБАВЛЕН", name);
        }
    });
}

// 3. ОБНОВЛЕНИЕ КЛИЕНТА
void DatabaseManager::updateCustomerAsync(int id, const QString &name, const QString &phone, const QString &email, const QString &address) {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) { emit customerOperationResult(false, "Нет соединения с БД"); return; }

        QSqlQuery query(db);
        query.prepare("UPDATE customers SET full_name = ?, phone = ?, email = ?, address = ? WHERE id = ?");
        query.addBindValue(name);
        query.addBindValue(phone);
        query.addBindValue(email);
        query.addBindValue(address);
        query.addBindValue(id);

        if (!query.exec()) {
            emit customerOperationResult(false, "Ошибка обновления: " + query.lastError().text());
        } else {
            emit customerOperationResult(true, "Данные обновлены");
            Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "ОБНОВЛЕН", "ID: " + QString::number(id));
        }
    });
}

// 4. УДАЛЕНИЕ КЛИЕНТА
void DatabaseManager::deleteCustomerAsync(int id) {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) { emit customerOperationResult(false, "Нет соединения с БД"); return; }

        QSqlQuery query(db);
        query.prepare("DELETE FROM customers WHERE id = ?");
        query.addBindValue(id);

        if (!query.exec()) {
            // Скорее всего сработает Foreign Key constraint, если есть заказы
            QString err = query.lastError().text();
            if (err.contains("constraint") || err.contains("foreign key")) {
                emit customerOperationResult(false, "Нельзя удалить покупателя, у которого есть заказы!");
            } else {
                emit customerOperationResult(false, "Ошибка удаления: " + err);
            }
        } else {
            emit customerOperationResult(true, "Покупатель удален");
            Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "УДАЛЕН", "ID: " + QString::number(id));
        }
    });
}

// 5. ИСТОРИЯ ЗАКАЗОВ КЛИЕНТА
void DatabaseManager::fetchCustomerOrdersAsync(int customerId) {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;
        if (!db.isOpen()) { emit customerOrdersLoaded(result); return; }

        QSqlQuery query(db);
        query.prepare("SELECT * FROM orders WHERE customer_id = ? ORDER BY created_at DESC");
        query.addBindValue(customerId);

        if (query.exec()) {
            while (query.next()) {
                QVariantMap row;
                QSqlRecord record = query.record();
                for (int i = 0; i < record.count(); ++i) {
                    row[record.fieldName(i)] = record.value(i);
                }
                result.append(row);
            }
        }
        emit customerOrdersLoaded(result);
    });
}

// 6. ОТЧЕТ ПО ПЕРИОДУ
void DatabaseManager::fetchReportAsync(const QString &startDate, const QString &endDate) {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;
        if (!db.isOpen()) { emit reportDataLoaded(result); return; }

        // Парсим даты
        QDate start = QDate::fromString(startDate, "yyyy-MM-dd"); // В QML мы конвертировали заранее
        QDate end = QDate::fromString(endDate, "yyyy-MM-dd");

        // Если конвертация не удалась, пробуем формат UI
        if (!start.isValid()) start = QDate::fromString(startDate, "dd.MM.yyyy");
        if (!end.isValid()) end = QDate::fromString(endDate, "dd.MM.yyyy");

        QDateTime startDt = start.startOfDay();
        QDateTime endDt = end.endOfDay();

        QSqlQuery query(db);
        query.prepare(
            "SELECT c.id, c.full_name, c.phone, c.email, c.address, "
            "COUNT(o.id) as order_count, SUM(o.total_amount) as total_amount "
            "FROM customers c "
            "INNER JOIN orders o ON c.id = o.customer_id "
            "WHERE o.created_at BETWEEN ? AND ? "
            "GROUP BY c.id, c.full_name, c.phone, c.email, c.address "
            "ORDER BY total_amount DESC"
            );
        query.addBindValue(startDt);
        query.addBindValue(endDt);

        if (query.exec()) {
            while (query.next()) {
                QVariantMap row;
                QSqlRecord record = query.record();
                for (int i = 0; i < record.count(); ++i) {
                    row[record.fieldName(i)] = record.value(i);
                }
                result.append(row);
            }
        } else {
            Logger::instance().log("Система", "ОТЧЕТ", "ОШИБКА", query.lastError().text());
        }
        emit reportDataLoaded(result);
    });
}

// 1. ЗАГРУЗКА СПИСКА ЗАКАЗОВ
void DatabaseManager::fetchOrders() {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;
        if (!db.isOpen()) { emit ordersLoaded(result); return; }

        QSqlQuery query(db);
        // Запрос с JOIN для получения имен клиентов и создателей
        QString queryStr = "SELECT "
                           "o.id, o.order_number, o.order_type, o.status, o.total_amount, o.created_at, o.notes, "
                           "c.full_name as customer_name, c.phone as customer_phone, "
                           "u.login as created_by_user "
                           "FROM orders o "
                           "LEFT JOIN customers c ON o.customer_id = c.id "
                           "LEFT JOIN users u ON o.created_by = u.id "
                           "ORDER BY o.created_at DESC";

        if (query.exec(queryStr)) {
            while (query.next()) {
                QVariantMap row;
                QSqlRecord record = query.record();
                for (int i = 0; i < record.count(); ++i) {
                    row[record.fieldName(i)] = record.value(i);
                }
                result.append(row);
            }
        }
        emit ordersLoaded(result);
    });
}

// 2. ЗАГРУЗКА СПРАВОЧНИКОВ (Для ComboBox)
void DatabaseManager::fetchReferenceData() {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantMap result;
        if (!db.isOpen()) { emit referenceDataLoaded(result); return; }

        // 2.1 Клиенты
        QVariantList customers;
        QSqlQuery qCust(db);
        if(qCust.exec("SELECT id, full_name, phone, email FROM customers ORDER BY full_name")) {
            while(qCust.next()) {
                QVariantMap c;
                c["id"] = qCust.value("id");
                c["display"] = qCust.value("full_name");
                c["phone"] = qCust.value("phone");
                c["email"] = qCust.value("email");
                customers.append(c);
            }
        }
        result["customers"] = customers;

        // 2.2 Наборы
        QVariantList kits;
        QSqlQuery qKits(db);
        if(qKits.exec("SELECT id, name, price FROM embroidery_kits WHERE is_active = 1 ORDER BY name")) {
            while(qKits.next()) {
                QVariantMap k;
                k["id"] = qKits.value("id");
                k["name"] = qKits.value("name");
                k["price"] = qKits.value("price");
                k["display"] = k["name"].toString() + " - " + k["price"].toString() + " ₽";
                kits.append(k);
            }
        }
        result["kits"] = kits;

        // 2.3 Материалы
        QVariantList materials;
        QSqlQuery qMat(db);
        if(qMat.exec("SELECT * FROM frame_materials ORDER BY name")) {
            while(qMat.next()) {
                QVariantMap m;
                m["id"] = qMat.value("id");
                m["price"] = qMat.value("price_per_meter");
                m["display"] = qMat.value("name").toString() + " (" + qMat.value("color").toString() + ") - " + qMat.value("price_per_meter").toString() + " ₽/м";
                materials.append(m);
            }
        }
        result["materials"] = materials;

        // 2.4 Мастера
        QVariantList masters;
        QSqlQuery qMas(db);
        if(qMas.exec("SELECT id, login FROM users WHERE role = 'Мастер производства' ORDER BY login")) {
            while(qMas.next()) {
                QVariantMap ms;
                ms["id"] = qMas.value("id");
                ms["display"] = qMas.value("login");
                masters.append(ms);
            }
        }
        result["masters"] = masters;

        emit referenceDataLoaded(result);
    });
}

// 3. СОЗДАНИЕ ЗАКАЗА (ТРАНЗАКЦИЯ)
void DatabaseManager::createOrderTransactionAsync(const QVariantMap &data) {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) { emit orderOperationResult(false, "Нет соединения"); return; }

        if (!db.transaction()) {
            emit orderOperationResult(false, "Не удалось начать транзакцию");
            return;
        }

        try {
            QSqlQuery query(db);

            // 1. Создаем сам заказ
            query.prepare("INSERT INTO orders (order_number, customer_id, order_type, total_amount, status, notes, created_by) "
                          "VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id");
            query.addBindValue(data["order_number"]);
            query.addBindValue(data["customer_id"]);
            query.addBindValue(data["order_type"]);
            query.addBindValue(data["total_amount"]);
            query.addBindValue(data["status"]);
            query.addBindValue(data["notes"]);
            query.addBindValue(currentUserId);

            if (!query.exec() || !query.next()) throw query.lastError().text();
            int orderId = query.value(0).toInt();

            // 2. Создаем детали
            if (data["order_type"].toString() == "Изготовление рамки") {
                // Расчет себестоимости (упрощенно, так как цену передали из UI)
                double prodCost = data["total_amount"].toDouble() * 0.5;

                query.prepare("INSERT INTO frame_orders (order_id, width, height, frame_material_id, "
                              "component_furniture_id, master_id, special_instructions, production_cost, selling_price) "
                              "VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?)");
                query.addBindValue(orderId);
                query.addBindValue(data["width"]);
                query.addBindValue(data["height"]);
                query.addBindValue(data["material_id"]);

                if (data["master_id"].toInt() > 0) query.addBindValue(data["master_id"]);
                else query.addBindValue(QVariant(QVariant::Int));

                query.addBindValue(data["notes"]);
                query.addBindValue(prodCost);
                query.addBindValue(data["total_amount"]);

                if (!query.exec()) throw "Ошибка создания рамки: " + query.lastError().text();

                // Списание материала (упрощенно)
                double meters = ((data["width"].toDouble() + data["height"].toDouble()) * 2 / 100.0) * 1.15;
                QSqlQuery stockQ(db);
                stockQ.prepare("UPDATE frame_materials SET stock_quantity = stock_quantity - ? WHERE id = ?");
                stockQ.addBindValue(meters);
                stockQ.addBindValue(data["material_id"]);
                stockQ.exec();

            } else { // Продажа набора
                query.prepare("INSERT INTO order_items (order_id, embroidery_kit_id, item_name, quantity, unit_price, total_price) "
                              "VALUES (?, ?, 'Готовый набор', ?, ?, ?)");
                query.addBindValue(orderId);
                query.addBindValue(data["kit_id"]);
                query.addBindValue(data["quantity"]);
                query.addBindValue(data["unit_price"]);
                query.addBindValue(data["total_amount"]); // Сумма = кол-во * цена

                if (!query.exec()) throw "Ошибка добавления товара: " + query.lastError().text();

                // Списание
                QSqlQuery stockQ(db);
                stockQ.prepare("UPDATE embroidery_kits SET stock_quantity = stock_quantity - ? WHERE id = ?");
                stockQ.addBindValue(data["quantity"]);
                stockQ.addBindValue(data["kit_id"]);
                stockQ.exec();
            }

            db.commit();
            emit orderOperationResult(true, "Заказ успешно создан");
            Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "СОЗДАН", "ID: " + QString::number(orderId));

        } catch (QString &err) {
            db.rollback();
            emit orderOperationResult(false, err);
        }
    });
}

// 4. ОБНОВЛЕНИЕ ЗАКАЗА
void DatabaseManager::updateOrderAsync(int id, const QString &status, double amount, const QString &notes) {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) { emit orderOperationResult(false, "Нет соединения"); return; }

        QSqlQuery query(db);
        QString sql = "UPDATE orders SET status = ?, total_amount = ?, notes = ?";
        if (status == "Завершён") sql += ", completed_at = CURRENT_TIMESTAMP";
        sql += " WHERE id = ?";

        query.prepare(sql);
        query.addBindValue(status);
        query.addBindValue(amount);
        query.addBindValue(notes);
        query.addBindValue(id);

        if (!query.exec()) {
            emit orderOperationResult(false, "Ошибка обновления: " + query.lastError().text());
        } else {
            emit orderOperationResult(true, "Заказ обновлен");
        }
    });
}

// 5. УДАЛЕНИЕ ЗАКАЗА
void DatabaseManager::deleteOrderAsync(int id) {
    QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) { emit orderOperationResult(false, "Нет соединения"); return; }

        QSqlQuery query(db);
        query.prepare("DELETE FROM orders WHERE id = ?");
        query.addBindValue(id);

        if (!query.exec()) {
            emit orderOperationResult(false, "Ошибка удаления: " + query.lastError().text());
        } else {
            emit orderOperationResult(true, "Заказ удален");
        }
    });
}
