#include "DatabaseManager.h"

// Белый список таблиц для защиты
const QStringList ALLOWED_TABLES = {
    "users", "customers", "frame_materials", "component_furniture",
    "embroidery_kits", "consumable_furniture", "orders",
    "frame_orders", "order_items"
};

DatabaseManager* DatabaseManager::m_instance = nullptr;
QMutex DatabaseManager::m_mutex;

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
}

bool DatabaseManager::initializeDatabase() {
    _database = QSqlDatabase::addDatabase("QPSQL");
    _database.setDatabaseName("failedmd16"); // имя бд
    _database.setHostName("pg4.sweb.ru"); // айпи хоста
    _database.setPort(5433); // порт хоста
    _database.setUserName("failedmd16");
    _database.setPassword("Bagetworkshop123");
    _database.setConnectOptions("requiressl=0;connect_timeout=10");

    if (!_database.open()) {
        qDebug() << "Сouldn't connect to the database: " << _database.lastError().text();
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

    QString createTableUsersQuery = "CREATE TABLE IF NOT EXISTS users ("
                                    "id SERIAL PRIMARY KEY, "
                                    "login TEXT UNIQUE NOT NULL, "
                                    "password TEXT NOT NULL, "
                                    "role TEXT NOT NULL CHECK(role IN ('Продавец', 'Мастер производства')), "
                                    "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)";

    if (!query.exec(createTableUsersQuery)) {
        qDebug() << "Error creating users table:" << query.lastError();
        return;
    }

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
        qDebug() << "Error creating customers table:" << query.lastError();
        return;
    }

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
        qDebug() << "Error creating frame_materials table:" << query.lastError();
        return;
    }

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
        qDebug() << "Error creating component_furniture table:" << query.lastError();
        return;
    }

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
        qDebug() << "Error creating embroidery_kits table:" << query.lastError();
        return;
    }

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
        qDebug() << "Error creating consumable_furniture table:" << query.lastError();
        return;
    }

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
        qDebug() << "Error creating orders table:" << query.lastError();
        return;
    }

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
        qDebug() << "Error creating frame_orders table:" << query.lastError();
        return;
    }

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
        qDebug() << "Error creating order_items table:" << query.lastError();
        return;
    }

    QStringList indexQueries;
    indexQueries << "CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id)"
                 << "CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at)"
                 << "CREATE INDEX IF NOT EXISTS idx_frame_orders_order_id ON frame_orders(order_id)"
                 << "CREATE INDEX IF NOT EXISTS idx_frame_orders_master_id ON frame_orders(master_id)"
                 << "CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id)"
                 << "CREATE INDEX IF NOT EXISTS idx_customers_full_name ON customers(full_name)";

    for(const QString &idxQ : indexQueries) {
        if(!query.exec(idxQ)) {
            qDebug() << "Warning creating index:" << query.lastError().text();
        }
    }

    qDebug() << "All tables created successfully!";
}

bool DatabaseManager::loginUser(const QString &login, const QString &password) {
    if (!_database.isOpen()) return false;

    QString hashedPassword = hashPassword(password);

    QSqlQuery query;
    query.prepare("SELECT id, role, password FROM users WHERE login = ?");
    query.addBindValue(login);

    if (!query.exec()) return false;

    if (query.next()) {
        if (query.value(2).toString() == hashedPassword) {
            currentUserId = query.value(0).toInt();
            currentUserRole = query.value(1).toString();
            return true;
        }
    }
    return false;
}

QString DatabaseManager::hashPassword(const QString &password) {
    QByteArray hash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256);

    return QString(hash.toHex());
}

bool DatabaseManager::validateLogin(const QString &login)
{
    if (login.length() < 3 || login.length() > 20) {
        return false;
    }

    QRegularExpression regex("^[a-zA-Z0-9_]+$");
    return regex.match(login).hasMatch();
}

bool DatabaseManager::validatePassword(const QString &password)
{
    if (password.length() < 6) {
        return false;
    }

    // Проверка на наличие хотя бы одной цифры
    QRegularExpression digitRegex("\\d");
    if (!digitRegex.match(password).hasMatch()) {
        return false;
    }

    // Проверка на наличие хотя бы одной буквы
    QRegularExpression letterRegex("[a-zA-Z]");
    return letterRegex.match(password).hasMatch();
}

bool DatabaseManager::registrationUser(const QString &login, const QString &password, const QString &role, const QString &code) {
    if (!_database.isOpen()) {
        qDebug() << "Database not connected.";
        return false;
    }

    if (code != adminCode) {
        qDebug() << "Invalid admin code.";
        return false;
    }

    if (!validateLogin(login)) {
        qDebug() << "Invalid login format.";
        return false;
    }

    if (!validatePassword(password)) {
        qDebug() << "Invalid password format.";
        return false;
    }

    QSqlQuery query;
    query.prepare("SELECT id FROM users WHERE login = ?");
    query.addBindValue(login);

    if (!query.exec()) {
        qDebug() << "Check user error:" << query.lastError();
        return false;
    }

    if (query.next()) {
        qDebug() << "User already exists.";
        return false;
    }

    QString hashedPassword = hashPassword(password);

    query.prepare("INSERT INTO users (login, password, role) VALUES (?, ?, ?)");
    query.addBindValue(login);
    query.addBindValue(hashedPassword);
    query.addBindValue(role);

    if (!query.exec()) {
        qDebug() << "Registration error:" << query.lastError();
        return false;
    }

    qDebug() << "User registered successfully. Login:" << login;
    return true;
}

int DatabaseManager::getCurrentUserID() {
    qDebug() << "User ID: " << currentUserId;

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
        qDebug() << "Error loading table" << name << ":" << model->lastError().text();
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
        qDebug() << "Error adding customer:" << query.lastError().text();
        return;
    }
}

void DatabaseManager::updateCustomer(int row, const QString &name, const QString &phone, const QString &email, const QString &address)
{
    QSqlQueryModel *model = getTableModel("customers");

    if (!model) {
        qDebug() << "Failed to load customers model";
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
}

void DatabaseManager::deleteCustomer(int row)
{
    QSqlQueryModel *model = getTableModel("customers");

    if (!model) {
        qDebug() << "Failed to load customers model";
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
}

int DatabaseManager::getRowCount(const QString &table)
{
    if (!ALLOWED_TABLES.contains(table))
        return 0;

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
        return query.value(0).toInt();
    }
    qDebug() << "Create Order Error:" << query.lastError().text();
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
        qDebug() << "Error updating order:" << query.lastError().text();
    }
}

void DatabaseManager::deleteOrder(int id)
{
    QSqlQuery query;
    query.prepare("DELETE FROM orders WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec()) {
        qDebug() << "Error deleting order:" << query.lastError().text();
    }
}

bool DatabaseManager::createFrameOrder(int orderId, double width, double height,
                                       int frameMaterialId, int componentFurnitureId,
                                       int masterId, const QString &specialInstructions) {
    QSqlQuery query;

    QSqlQuery checkFurn("SELECT id FROM component_furniture WHERE id = " + QString::number(componentFurnitureId));
    if (!checkFurn.exec() || !checkFurn.next()) {
        QSqlQuery fixFurn("SELECT id FROM component_furniture LIMIT 1");
        if (fixFurn.next()) {
            componentFurnitureId = fixFurn.value(0).toInt();
        } else {
            qDebug() << "Error: No furniture found in DB!";
            return false;
        }
    }

    QSqlQuery matQuery;
    matQuery.prepare("SELECT price_per_meter FROM frame_materials WHERE id = ?");
    matQuery.addBindValue(frameMaterialId);

    double pricePerMeter = 0.0;
    if (matQuery.exec() && matQuery.next()) {
        pricePerMeter = matQuery.value(0).toDouble();
    }

    // Расчет: (Периметр в метрах * 1.15 запас) * цена + 500 работа
    double metersNeeded = ((width + height) * 2 / 100.0) * 1.15;
    double productionCost = (metersNeeded * pricePerMeter) + 500.0;
    double sellingPrice = productionCost * 2.0;

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
    else query.addBindValue(QVariant(QVariant::Int)); // NULL

    query.addBindValue(specialInstructions);
    query.addBindValue(productionCost);
    query.addBindValue(sellingPrice);

    if (!query.exec()) {
        qDebug() << "Error creating frame order:" << query.lastError().text();
        return false;
    }

    QSqlQuery updateStock;
    updateStock.prepare("UPDATE frame_materials SET stock_quantity = stock_quantity - ? WHERE id = ?");
    updateStock.addBindValue(metersNeeded);
    updateStock.addBindValue(frameMaterialId);
    updateStock.exec();

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
        qDebug() << "Error creating order item:" << query.lastError().text();
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

    if (!stockQuery.exec()) {
        qDebug() << "Error updating stock:" << stockQuery.lastError().text();
    }

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
        qDebug() << "Error updating order status:" << query.lastError().text();
        return false;
    }
    return true;
}

QSqlQueryModel* DatabaseManager::getFrameMaterialsModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    QString queryStr = "SELECT * FROM frame_materials ORDER BY name";
    model->setQuery(queryStr, _database);

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
        return;
    }

    int id = model->data(model->index(row, 0)).toInt();

    QSqlQuery query;
    query.prepare("DELETE FROM frame_materials WHERE id = ?");
    query.addBindValue(id);

    if (!query.exec())
        qDebug() << "Error deleting frame material:" << query.lastError().text();
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

    if (!query.exec())
        qDebug() << "Error deleting component furniture:" << query.lastError().text();
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
        qDebug() << "Error adding embroidery kit:" << query.lastError().text();
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
        qDebug() << "Error adding consumable furniture:" << query.lastError().text();
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
    query.exec();
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
    query.exec();
}

void DatabaseManager::deleteEmbroideryKit(int id) {
    QSqlQuery query;
    query.prepare("DELETE FROM embroidery_kits WHERE id = ?");
    query.addBindValue(id);
    if (!query.exec()) {
        qDebug() << "Error deleting embroidery kit:" << query.lastError().text();
    }
}

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
        qDebug() << "Error report:" << query.lastError().text();
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
    query.prepare("SELECT lastval()");

    if (query.exec() && query.next()) {
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
        qDebug() << "Error loading master orders:" << query.lastError().text();
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
