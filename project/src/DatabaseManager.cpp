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

    QSqlDatabase::removeDatabase(connectionName); // Пофиксить кривое соединение, когда выходим из аккаунта (возвращаемся в LoginPage),
                                                  // то происходит ошибка с дубликатом соединения
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
                                "order_type TEXT NOT NULL CHECK(order_type IN ('frame_production', 'kit_sale')), "
                                "total_amount REAL NOT NULL, "
                                "status TEXT NOT NULL CHECK(status IN ('new', 'in_progress', 'ready', 'completed', 'cancelled')), "
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
                                    "item_type TEXT NOT NULL CHECK(item_type IN ('embroidery_kit', 'consumable_furniture')), "
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
        // Сохраняем ID и роль текущего пользователя
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
