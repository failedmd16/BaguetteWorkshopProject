#include "DatabaseManager.h"

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

    if (!_database.open()) {
        qDebug() << "Сouldn't connect to the database: " << _database.lastError().text();
        return false;
    }

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

bool DatabaseManager::loginUser(const QString &login, const QString &password) {
    if (!_database.isOpen()) {
        qDebug() << "Database not connected.";
        return false;
    }

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

    return false;
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

    QString queryStr = "SELECT * FROM " + name;
    model->setQuery(queryStr, _database);

    if (model->lastError().isValid()) {
        qDebug() << "Error loading table" << name << ":" << model->lastError().text();
    } else {
        if (model->rowCount() > 0) {
            QSqlRecord record = model->record(0);
        }
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
    QSqlQuery query;
    query.prepare("SELECT COUNT(*) FROM " + table);

    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

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

    return true;
}

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

    double productionCost = (width * height / 10000) * 500;
    double sellingPrice = productionCost * 1.3;

    query.addBindValue(productionCost);
    query.addBindValue(sellingPrice);

    if (!query.exec()) {
        qDebug() << "Error creating frame order:" << query.lastError().text();
        return false;
    }

    return true;
}

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

QSqlQueryModel* DatabaseManager::getFrameMaterialsModel() {
    QSqlQueryModel* model = new QSqlQueryModel(this);
    QString queryStr = "SELECT * FROM frame_materials ORDER BY name";
    qDebug() << "Executing query:" << queryStr;
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
    QString queryStr = "SELECT "
                       "o.id, o.order_number, o.order_type, o.status, o.total_amount, o.created_at, "
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
    QString queryStr = "SELECT "
                       "o.id, o.order_number, o.order_type, o.status, o.total_amount, o.created_at, "
                       "c.full_name as customer_name, c.phone as customer_phone, "
                       "fo.width, fo.height, fo.special_instructions "
                       "FROM orders o "
                       "LEFT JOIN customers c ON o.customer_id = c.id "
                       "LEFT JOIN frame_orders fo ON o.id = fo.order_id "
                       "WHERE o.order_type = 'Изготовление рамки' "  // Фильтр для мастера
                       "ORDER BY o.created_at DESC";

    if (!query.exec(queryStr)) {
        qDebug() << "Error loading master orders data:" << query.lastError().text();
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
