#include "DatabaseManager.h"

/*!
 * \brief Список таблиц базы данных.
 * Используется для проверки допустимости операций экспорта, импорта и резервного копирования.
 */
const QStringList tables = {
    "users", "customers", "frame_materials", "component_furniture",
    "embroidery_kits", "consumable_furniture", "orders",
    "frame_orders", "order_items", "event_logs"
};

DatabaseManager* DatabaseManager::m_instance = nullptr;
QMutex DatabaseManager::m_mutex;
QMutex DatabaseManager::m_connectionMutex;

/*!
 * \brief Конструктор DatabaseManager.
 * Пытается инициализировать подключение к базе данных при создании.
 * В случае неудачи пишет лог в систему логирования.
 */
DatabaseManager::DatabaseManager(QObject *parent) : QObject(parent) {
    if (!initializeDatabase()) {
        Logger::instance().log("Система", "БД", "СБОЙ_ИНИЦИАЛИЗАЦИИ", "Не удалось инициализировать подключение к базе данных");
    }
}

/*!
 * \brief Деструктор DatabaseManager.
 * Закрывает соединение с базой данных, если оно открыто.
 */
DatabaseManager::~DatabaseManager() {
    if (_database.isOpen()) {
        _database.close();
    }
}

/*!
 * \brief Инициализирует основное подключение к базе данных PostgreSQL.
 * \return true, если подключение успешно установлено, иначе false.
 */
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

    return true;
}

/*!
 * \brief Возвращает единственный экземпляр класса (Singleton).
 * Если экземпляр еще не создан, создает его.
 */
DatabaseManager* DatabaseManager::instance() {
    if (!m_instance) {
        m_instance = new DatabaseManager();
    }
    return m_instance;
}

/*!
 * \brief Уничтожает единственный экземпляр класса.
 * Метод потокобезопасен.
 */
void DatabaseManager::destroyInstance() {
    QMutexLocker locker(&m_mutex);
    if (m_instance) {
        delete m_instance;
        m_instance = nullptr;
    }
}

/*!
 * \brief Возвращает ID текущего авторизованного пользователя.
 */
int DatabaseManager::getCurrentUserID() {
    return currentUserId;
}

/*!
 * \brief Возвращает роль текущего авторизованного пользователя.
 */
QString DatabaseManager::getCurrentUserRole() const {
    return currentUserRole;
}

/*!
 * \brief Хеширует пароль с использованием алгоритма SHA-256.
 * \return Хеш пароля в шестнадцатеричном формате.
 */
QString DatabaseManager::hashPassword(const QString &password) {
    QByteArray hash = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256);
    return QString(hash.toHex());
}

/*!
 * \brief Проверяет валидность логина.
 * Логин должен состоять из латинских букв, цифр или подчеркиваний, длиной от 3 до 20 символов.
 */
bool DatabaseManager::validateLogin(const QString &login) {
    if (login.length() < 3 || login.length() > 20) {
        return false;
    }
    QRegularExpression regex("^[a-zA-Z0-9_]+$");
    return regex.match(login).hasMatch();
}

/*!
 * \brief Проверяет валидность пароля.
 * Пароль должен быть не короче 6 символов и содержать как цифры, так и буквы.
 */
bool DatabaseManager::validatePassword(const QString &password) {
    if (password.length() < 6) {
        return false;
    }
    QRegularExpression digitRegex("\\d");
    if (!digitRegex.match(password).hasMatch()) {
        return false;
    }
    QRegularExpression letterRegex("[a-zA-Z]");
    return letterRegex.match(password).hasMatch();
}

/*!
 * \brief Получает или создает подключение к БД, уникальное для текущего потока.
 * Используется в методах QtConcurrent для предотвращения конфликтов доступа к БД из разных потоков.
 * Имя соединения генерируется на основе адреса текущего потока.
 */
QSqlDatabase DatabaseManager::getThreadLocalConnection() {
    QString connectionName = "ThreadConn_" + QString::number((quint64)QThread::currentThread(), 16);
    QMutexLocker locker(&m_connectionMutex);

    QSqlDatabase db;

    if (QSqlDatabase::contains(connectionName)) {
        db = QSqlDatabase::database(connectionName);
        if (db.isOpen()) {
            QSqlQuery q(db);
            if (q.exec("SELECT 1")) {
                return db;
            }
        }
        db.close();
    }

    if (!QSqlDatabase::contains(connectionName)) {
        db = QSqlDatabase::addDatabase("QPSQL", connectionName);
    } else {
        db = QSqlDatabase::database(connectionName);
    }

    db.setDatabaseName("failedmd16");
    db.setHostName("pg4.sweb.ru");
    db.setPort(5433);
    db.setUserName("failedmd16");
    db.setPassword("Bagetworkshop123");
    db.setConnectOptions("requiressl=0;connect_timeout=5");

    if (!db.open()) {
        qDebug() << "Thread connection error:" << db.lastError().text();
    }

    return db;
}

/*!
 * \brief Асинхронно выполняет вход пользователя.
 * Проверяет учетные данные и эмитит сигнал loginResult.
 */
void DatabaseManager::loginUserAsync(const QString &login, const QString &password) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit loginResult(false, "", "Ошибка подключения к базе данных");
            return;
        }

        QString hashedPassword = hashPassword(password);
        QSqlQuery query(db);
        query.prepare("SELECT id, role, password FROM users WHERE login = ?");
        query.addBindValue(login);

        if (!query.exec()) {
            Logger::instance().log(login, "АВТОРИЗАЦИЯ", "ОШИБКА_SQL", query.lastError().text());
            emit loginResult(false, "", "Ошибка базы данных");
            return;
        }

        if (query.next()) {
            QString storedPassword = query.value(2).toString();

            if (storedPassword == hashedPassword) {
                int userId = query.value(0).toInt();
                QString role = query.value(1).toString();

                this->currentUserId = userId;
                this->currentUserRole = role;

                Logger::instance().log(login, "АВТОРИЗАЦИЯ", "ВХОД_УСПЕШЕН", "Роль: " + role);
                emit loginResult(true, role, "Вход выполнен");
            } else {
                Logger::instance().log(login, "АВТОРИЗАЦИЯ", "ВХОД_ПРОВАЛЕН", "Неверный пароль");
                emit loginResult(false, "", "Неверный пароль");
            }
        } else {
            Logger::instance().log(login, "АВТОРИЗАЦИЯ", "ВХОД_ПРОВАЛЕН", "Пользователь не найден");
            emit loginResult(false, "", "Пользователь не найден");
        }
    });
}

/*!
 * \brief Асинхронно регистрирует нового пользователя.
 * Проверяет валидность данных, уникальность логина и создает запись.
 */
void DatabaseManager::registerUserAsync(const QString &login, const QString &password, const QString &role) {
    auto future = QtConcurrent::run([=]() {
        if (!validateLogin(login) || !validatePassword(password)) {
            emit userOperationResult(false, "Некорректный логин или пароль (Логин: 3-20 симв., Пароль: мин 6, цифры+буквы)");
            Logger::instance().log("Админ", "УПР_ПОЛЬЗОВАТЕЛЯМИ", "ОШИБКА_РЕГИСТРАЦИИ", "Валидация не прошла: " + login);
            return;
        }

        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit userOperationResult(false, "Ошибка соединения с базой данных");
            return;
        }

        QSqlQuery query(db);
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

/*!
 * \brief Асинхронно обновляет пароль пользователя.
 */
void DatabaseManager::updateUserPasswordAsync(const QString &login, const QString &newPassword) {
    auto future = QtConcurrent::run([=]() {
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

/*!
 * \brief Проверяет наличие хотя бы одного администратора в системе.
 */
bool DatabaseManager::hasAdminAccount() {
    if (!_database.isOpen()) {
        return false;
    }

    QSqlQuery query;
    if (query.exec("SELECT COUNT(*) FROM users WHERE role = 'Администратор'")) {
        if (query.next()) {
            return query.value(0).toInt() > 0;
        }
    }
    return false;
}

/*!
 * \brief Создает первого администратора системы.
 * Метод доступен только если hasAdminAccount() возвращает false.
 */
void DatabaseManager::createFirstAdminAsync(const QString &login, const QString &password) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit firstAdminCreatedResult(false, "Ошибка подключения к БД");
            return;
        }

        QSqlQuery checkQuery(db);
        if (checkQuery.exec("SELECT COUNT(*) FROM users WHERE role = 'Администратор'")) {
            if (checkQuery.next() && checkQuery.value(0).toInt() > 0) {
                emit firstAdminCreatedResult(false, "Администратор уже существует!");
                return;
            }
        }

        if (!validateLogin(login) || !validatePassword(password)) {
            emit firstAdminCreatedResult(false, "Некорректный логин или пароль");
            return;
        }

        QString hashedPassword = hashPassword(password);
        QSqlQuery query(db);
        query.prepare("INSERT INTO users (login, password, role) VALUES (?, ?, 'Администратор')");
        query.addBindValue(login);
        query.addBindValue(hashedPassword);

        if (!query.exec()) {
            Logger::instance().log("Система", "АВТОРИЗАЦИЯ", "ОШИБКА_АДМИНА", query.lastError().text());
            emit firstAdminCreatedResult(false, "Ошибка SQL: " + query.lastError().text());
            return;
        }

        int newUserId = -1;
        QSqlQuery idQuery(db);
        if (idQuery.exec("SELECT id FROM users WHERE login = '" + login + "'") && idQuery.next()) {
            newUserId = idQuery.value(0).toInt();
        }

        this->currentUserId = newUserId;
        this->currentUserRole = "Администратор";

        Logger::instance().log("Система", "АВТОРИЗАЦИЯ", "АДМИН_СОЗДАН", "Первый администратор зарегистрирован");
        emit firstAdminCreatedResult(true, "Администратор успешно создан");
    });
}

/*!
 * \brief Асинхронно загружает список всех покупателей.
 */
void DatabaseManager::fetchCustomers() {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;
        if (!db.isOpen()) {
            emit customersLoaded(result);
            return;
        }

        QSqlQuery query(db);
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

/*!
 * \brief Асинхронно добавляет нового покупателя.
 */
void DatabaseManager::addCustomerAsync(const QString &name, const QString &phone, const QString &email, const QString &address) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit customerOperationResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        query.prepare("INSERT INTO customers (full_name, phone, email, address, created_by) VALUES (?, ?, ?, ?, ?)");
        query.addBindValue(name);
        query.addBindValue(phone);
        query.addBindValue(email);
        query.addBindValue(address);
        query.addBindValue(currentUserId);

        if (!query.exec()) {
            emit customerOperationResult(false, "Ошибка добавления: " + query.lastError().text());
        } else {
            emit customerOperationResult(true, "Покупатель успешно добавлен");
            Logger::instance().log(QString::number(currentUserId), "КЛИЕНТЫ", "ДОБАВЛЕН", name);
        }
    });
}

/*!
 * \brief Асинхронно обновляет данные существующего покупателя.
 */
void DatabaseManager::updateCustomerAsync(int id, const QString &name, const QString &phone, const QString &email, const QString &address) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit customerOperationResult(false, "Нет соединения с БД");
            return;
        }

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

/*!
 * \brief Асинхронно удаляет покупателя.
 * Если у покупателя есть заказы, операция может быть отклонена БД.
 */
void DatabaseManager::deleteCustomerAsync(int id) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit customerOperationResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        query.prepare("DELETE FROM customers WHERE id = ?");
        query.addBindValue(id);

        if (!query.exec()) {
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

/*!
 * \brief Асинхронно загружает заказы конкретного покупателя.
 */
void DatabaseManager::fetchCustomerOrdersAsync(int customerId) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;
        if (!db.isOpen()) {
            emit customerOrdersLoaded(result);
            return;
        }

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

/*!
 * \brief Асинхронно формирует отчет по клиентам за выбранный период.
 * Группирует данные по клиентам, подсчитывая количество заказов и общую сумму.
 */
void DatabaseManager::fetchReportAsync(const QString &startDate, const QString &endDate) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;
        if (!db.isOpen()) {
            emit reportDataLoaded(result);
            return;
        }

        QDate start = QDate::fromString(startDate, "yyyy-MM-dd");
        QDate end = QDate::fromString(endDate, "yyyy-MM-dd");

        if (!start.isValid()) {
            start = QDate::fromString(startDate, "dd.MM.yyyy");
        }
        if (!end.isValid()) {
            end = QDate::fromString(endDate, "dd.MM.yyyy");
        }

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

/*!
 * \brief Возвращает ID специального клиента "Розничный покупатель".
 * Если такого клиента нет, создает его.
 */
int DatabaseManager::getRetailCustomerId() {
    QSqlQuery query(_database);
    if (query.exec("SELECT id FROM customers WHERE full_name = 'Розничный покупатель'") && query.next()) {
        return query.value(0).toInt();
    }
    query.prepare("INSERT INTO customers (full_name, phone, email, address, created_by) "
                  "VALUES ('Розничный покупатель', '-', '-', 'Магазин', ?) RETURNING id");
    query.addBindValue(currentUserId);
    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }

    return -1;
}

/*!
 * \brief Асинхронно загружает список всех заказов.
 */
void DatabaseManager::fetchOrders() {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;
        if (!db.isOpen()) {
            emit ordersLoaded(result);
            return;
        }

        QSqlQuery query(db);
        QString sql = "SELECT o.id, o.order_number, o.order_type, o.status, "
                      "o.total_amount, o.created_at, o.notes, "
                      "c.full_name as customer_name, c.phone as customer_phone "
                      "FROM orders o "
                      "LEFT JOIN customers c ON o.customer_id = c.id "
                      "ORDER BY o.created_at DESC";

        if (query.exec(sql)) {
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

/*!
 * \brief Асинхронно загружает справочные данные для форм (клиенты, материалы, мастера).
 * Агрегирует данные из нескольких таблиц в один QVariantMap.
 */
void DatabaseManager::fetchReferenceData() {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantMap result;
        if (!db.isOpen()) {
            emit referenceDataLoaded(result);
            return;
        }

        QVariantList customers;
        QSqlQuery qCust(db);
        if (qCust.exec("SELECT id, full_name, phone, email FROM customers ORDER BY full_name")) {
            while (qCust.next()) {
                QVariantMap c;
                c["id"] = qCust.value("id");
                c["display"] = qCust.value("full_name");
                c["phone"] = qCust.value("phone");
                c["email"] = qCust.value("email");
                customers.append(c);
            }
        }
        result["customers"] = customers;

        QVariantList kits;
        QSqlQuery qKits(db);
        if (qKits.exec("SELECT id, name, price FROM embroidery_kits WHERE stock_quantity > 0 ORDER BY name")) {
            while (qKits.next()) {
                QVariantMap k;
                k["id"] = qKits.value("id");
                k["name"] = qKits.value("name");
                k["price"] = qKits.value("price");
                k["display"] = k["name"].toString() + " (" + k["price"].toString() + " ₽)";
                kits.append(k);
            }
        }
        result["kits"] = kits;

        QVariantList materials;
        QSqlQuery qMat(db);
        if (qMat.exec("SELECT id, name, color, price_per_meter FROM frame_materials WHERE is_active = TRUE ORDER BY name")) {
            while (qMat.next()) {
                QVariantMap m;
                m["id"] = qMat.value("id");
                m["price"] = qMat.value("price_per_meter");
                m["display"] = qMat.value("name").toString() + " " + qMat.value("color").toString() +
                               " (" + qMat.value("price_per_meter").toString() + " ₽/м)";
                materials.append(m);
            }
        }
        result["materials"] = materials;

        QVariantList masters;
        QSqlQuery qMas(db);
        if (qMas.exec("SELECT id, login FROM users WHERE role = 'Мастер производства' AND role != 'Администратор' ORDER BY login")) {
            while (qMas.next()) {
                QVariantMap ms;
                ms["id"] = qMas.value("id");
                ms["display"] = qMas.value("login");
                masters.append(ms);
            }
        }
        result["masters"] = masters;

        QVariantList furniture;
        QSqlQuery qFurn(db);
        if (qFurn.exec("SELECT id, name, price_per_unit FROM component_furniture WHERE is_active = TRUE ORDER BY name")) {
            while (qFurn.next()) {
                QVariantMap f;
                f["id"] = qFurn.value("id");
                QString name = qFurn.value("name").toString();
                double price = qFurn.value("price_per_unit").toDouble();
                f["name"] = name;
                f["price"] = price;
                f["display"] = name + " (" + QString::number(price) + " ₽)";
                furniture.append(f);
            }
        }
        result["furniture"] = furniture;

        emit referenceDataLoaded(result);
    });
}

/*!
 * \brief Асинхронно создает заказ в рамках транзакции.
 * Обрабатывает создание заказа, деталей (рамки или набора) и списание материалов со склада.
 * При ошибке на любом этапе выполняет rollback.
 */
void DatabaseManager::createOrderTransactionAsync(const QVariantMap &data) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit orderOperationResult(false, "Нет соединения с базой данных");
            return;
        }

        if (!db.transaction()) {
            emit orderOperationResult(false, "Не удалось начать транзакцию");
            return;
        }

        QSqlQuery query(db);
        int orderId = -1;

        query.prepare("INSERT INTO orders (order_number, customer_id, order_type, total_amount, status, notes, created_by) "
                      "VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id");
        query.addBindValue(data["order_number"]);
        query.addBindValue(data["customer_id"]);
        query.addBindValue(data["order_type"]);
        query.addBindValue(data["total_amount"]);
        query.addBindValue(data["status"]);
        query.addBindValue(data["notes"]);
        query.addBindValue(currentUserId);

        if (!query.exec()) {
            QString err = query.lastError().text();
            db.rollback();
            emit orderOperationResult(false, "Ошибка создания заказа: " + err);
            return;
        }

        if (query.next()) {
            orderId = query.value(0).toInt();
        } else {
            db.rollback();
            emit orderOperationResult(false, "Не удалось получить номер заказа");
            return;
        }

        QString type = data["order_type"].toString();

        if (type == "Изготовление рамки") {
            int compId = data["component_id"].toInt();

            if (compId <= 0) {
                db.rollback();
                emit orderOperationResult(false, "Ошибка: Не выбрана фурнитура!");
                return;
            }

            query.prepare("INSERT INTO frame_orders (order_id, width, height, frame_material_id, "
                          "component_furniture_id, master_id, production_cost, selling_price, special_instructions) "
                          "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
            query.addBindValue(orderId);
            query.addBindValue(data["width"]);
            query.addBindValue(data["height"]);
            query.addBindValue(data["material_id"]);
            query.addBindValue(compId);

            int masterId = data["master_id"].toInt();
            if (masterId > 0) {
                query.addBindValue(masterId);
            } else {
                query.addBindValue(QVariant(QVariant::Int));
            }

            double price = data["total_amount"].toDouble();
            query.addBindValue(price * 0.4);
            query.addBindValue(price);
            query.addBindValue(data["notes"]);

            if (!query.exec()) {
                QString err = query.lastError().text();
                db.rollback();
                emit orderOperationResult(false, "Ошибка добавления рамки: " + err);
                return;
            }

            double meters = ((data["width"].toDouble() + data["height"].toDouble()) * 2 / 100.0) * 1.15;
            QSqlQuery stockQ(db);
            stockQ.prepare("UPDATE frame_materials SET stock_quantity = stock_quantity - ? WHERE id = ?");
            stockQ.addBindValue(meters);
            stockQ.addBindValue(data["material_id"]);
            if (!stockQ.exec()) {
                db.rollback();
                emit orderOperationResult(false, "Ошибка списания багета: " + stockQ.lastError().text());
                return;
            }

            QSqlQuery stockComp(db);
            stockComp.prepare("UPDATE component_furniture SET stock_quantity = stock_quantity - 1 WHERE id = ?");
            stockComp.addBindValue(compId);
            if (!stockComp.exec()) {
                db.rollback();
                emit orderOperationResult(false, "Ошибка списания фурнитуры: " + stockComp.lastError().text());
                return;
            }

        } else if (type == "Продажа набора") {
            query.prepare("INSERT INTO order_items (order_id, embroidery_kit_id, item_name, quantity, unit_price, total_price) "
                          "VALUES (?, ?, 'Готовый набор', ?, ?, ?)");
            query.addBindValue(orderId);
            query.addBindValue(data["kit_id"]);
            query.addBindValue(data["quantity"]);
            query.addBindValue(data["unit_price"]);
            query.addBindValue(data["total_amount"]);

            if (!query.exec()) {
                QString err = query.lastError().text();
                db.rollback();
                emit orderOperationResult(false, "Ошибка продажи набора: " + err);
                return;
            }

            QSqlQuery stockQ(db);
            stockQ.prepare("UPDATE embroidery_kits SET stock_quantity = stock_quantity - ? WHERE id = ?");
            stockQ.addBindValue(data["quantity"]);
            stockQ.addBindValue(data["kit_id"]);
            if (!stockQ.exec()) {
                db.rollback();
                emit orderOperationResult(false, "Ошибка списания набора: " + stockQ.lastError().text());
                return;
            }
        }

        if (db.commit()) {
            emit orderOperationResult(true, "Заказ успешно создан");
            Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "СОЗДАН", "ID: " + QString::number(orderId));
        } else {
            db.rollback();
            emit orderOperationResult(false, "Ошибка завершения транзакции: " + db.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно обновляет основные данные заказа.
 */
void DatabaseManager::updateOrderAsync(int id, const QString &status, double amount, const QString &notes) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit orderOperationResult(false, "Нет соединения");
            return;
        }

        QSqlQuery query(db);
        QString sql = "UPDATE orders SET status = ?, total_amount = ?, notes = ?";
        if (status == "Завершён") {
            sql += ", completed_at = CURRENT_TIMESTAMP";
        }
        sql += " WHERE id = ?";

        query.prepare(sql);
        query.addBindValue(status);
        query.addBindValue(amount);
        query.addBindValue(notes);
        query.addBindValue(id);

        if (!query.exec()) {
            emit orderOperationResult(false, "Ошибка SQL: " + query.lastError().text());
        } else {
            emit orderOperationResult(true, "Заказ обновлен");
        }
    });
}

/*!
 * \brief Асинхронно удаляет заказ.
 */
void DatabaseManager::deleteOrderAsync(int id) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit orderOperationResult(false, "Нет соединения");
            return;
        }

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

/*!
 * \brief Асинхронно обновляет статус заказа.
 * При статусе "Завершён" устанавливает дату завершения.
 */
void DatabaseManager::updateOrderStatusAsync(int id, const QString &newStatus) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit statusUpdateResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        QString sql;
        if (newStatus == "Завершён") {
            sql = "UPDATE orders SET status = ?, completed_at = CURRENT_TIMESTAMP WHERE id = ?";
        } else {
            sql = "UPDATE orders SET status = ?, completed_at = NULL WHERE id = ?";
        }

        query.prepare(sql);
        query.addBindValue(newStatus);
        query.addBindValue(id);

        if (!query.exec()) {
            emit statusUpdateResult(false, "Ошибка SQL: " + query.lastError().text());
        } else {
            emit statusUpdateResult(true, "Статус успешно изменен");
            Logger::instance().log(QString::number(currentUserId), "ЗАКАЗЫ", "СТАТУС_ОБНОВЛЕН", "ID: " + QString::number(id) + " -> " + newStatus);
        }
    });
}

/*!
 * \brief Асинхронно загружает список товаров (наборы для вышивания или расходные материалы).
 */
void DatabaseManager::fetchProductsAsync(bool isKit) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;

        if (!db.isOpen()) {
            emit productsLoaded(result);
            return;
        }

        QSqlQuery query(db);
        if (isKit) {
            query.prepare("SELECT * FROM embroidery_kits ORDER BY id DESC");
        } else {
            query.prepare("SELECT * FROM consumable_furniture ORDER BY id DESC");
        }

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
        emit productsLoaded(result);
    });
}

/*!
 * \brief Асинхронно добавляет новый набор для вышивания.
 */
void DatabaseManager::addEmbroideryKitAsync(const QString &name, const QString &description, double price, int quantity) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit productOperationResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        query.prepare("INSERT INTO embroidery_kits (name, description, price, stock_quantity, created_by) VALUES (?, ?, ?, ?, ?)");
        query.addBindValue(name);
        query.addBindValue(description);
        query.addBindValue(price);
        query.addBindValue(quantity);
        query.addBindValue(currentUserId);

        if (query.exec()) {
            emit productOperationResult(true, "Набор добавлен");
        } else {
            emit productOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно обновляет данные набора для вышивания.
 */
void DatabaseManager::updateEmbroideryKitAsync(int id, const QString &name, const QString &description, double price, int quantity) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit productOperationResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        query.prepare("UPDATE embroidery_kits SET name = ?, description = ?, price = ?, stock_quantity = ? WHERE id = ?");
        query.addBindValue(name);
        query.addBindValue(description);
        query.addBindValue(price);
        query.addBindValue(quantity);
        query.addBindValue(id);

        if (query.exec()) {
            emit productOperationResult(true, "Набор обновлен");
        } else {
            emit productOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно удаляет набор для вышивания.
 */
void DatabaseManager::deleteEmbroideryKitAsync(int id) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit productOperationResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        query.prepare("DELETE FROM embroidery_kits WHERE id = ?");
        query.addBindValue(id);

        if (query.exec()) {
            emit productOperationResult(true, "Набор удален");
        } else {
            emit productOperationResult(false, "Ошибка удаления: " + query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно добавляет расходную фурнитуру.
 */
void DatabaseManager::addConsumableAsync(const QString &name, const QString &type, double price, int quantity, const QString &unit) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit productOperationResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        query.prepare("INSERT INTO consumable_furniture (name, type, price_per_unit, stock_quantity, unit, created_by) VALUES (?, ?, ?, ?, ?, ?)");
        query.addBindValue(name);
        query.addBindValue(type);
        query.addBindValue(price);
        query.addBindValue(quantity);
        query.addBindValue(unit);
        query.addBindValue(currentUserId);

        if (query.exec()) {
            emit productOperationResult(true, "Фурнитура добавлена");
        } else {
            emit productOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно обновляет данные расходной фурнитуры.
 */
void DatabaseManager::updateConsumableAsync(int id, const QString &name, const QString &type, double price, int quantity, const QString &unit) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit productOperationResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        query.prepare("UPDATE consumable_furniture SET name = ?, type = ?, price_per_unit = ?, stock_quantity = ?, unit = ? WHERE id = ?");
        query.addBindValue(name);
        query.addBindValue(type);
        query.addBindValue(price);
        query.addBindValue(quantity);
        query.addBindValue(unit);
        query.addBindValue(id);

        if (query.exec()) {
            emit productOperationResult(true, "Фурнитура обновлена");
        } else {
            emit productOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно удаляет расходную фурнитуру.
 */
void DatabaseManager::deleteConsumableAsync(int id) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit productOperationResult(false, "Нет соединения с БД");
            return;
        }

        QSqlQuery query(db);
        query.prepare("DELETE FROM consumable_furniture WHERE id = ?");
        query.addBindValue(id);

        if (query.exec()) {
            emit productOperationResult(true, "Фурнитура удалена");
        } else {
            emit productOperationResult(false, "Ошибка удаления: " + query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно обрабатывает розничную продажу.
 * Создает заказ на "Розничного покупателя", добавляет позиции и списывает товар со склада в одной транзакции.
 */
void DatabaseManager::processRetailSaleAsync(int productId, bool isKit, int quantity, double unitPrice) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit productOperationResult(false, "Нет соединения с БД");
            return;
        }

        if (!db.transaction()) {
            emit productOperationResult(false, "Не удалось начать транзакцию");
            return;
        }

        int retailId = -1;
        QSqlQuery qCust(db);
        if (qCust.exec("SELECT id FROM customers WHERE full_name = 'Розничный покупатель'") && qCust.next()) {
            retailId = qCust.value(0).toInt();
        } else {
            QSqlQuery qIns(db);
            qIns.prepare("INSERT INTO customers (full_name, phone, email, address, created_by) VALUES ('Розничный покупатель', '-', '-', 'Магазин', ?) RETURNING id");
            qIns.addBindValue(currentUserId);
            if (qIns.exec() && qIns.next()) {
                retailId = qIns.value(0).toInt();
            }
        }

        if (retailId == -1) {
            db.rollback();
            emit productOperationResult(false, "Ошибка: Не удалось найти покупателя");
            return;
        }

        QSqlQuery qOrder(db);
        qOrder.prepare("INSERT INTO orders (order_number, customer_id, order_type, total_amount, status, notes, created_by, completed_at) "
                       "VALUES (?, ?, 'Продажа набора', ?, 'Завершён', 'Быстрая продажа', ?, CURRENT_TIMESTAMP) RETURNING id");
        qOrder.addBindValue("SALE-" + QString::number(QDateTime::currentMSecsSinceEpoch()));
        qOrder.addBindValue(retailId);
        qOrder.addBindValue(quantity * unitPrice);
        qOrder.addBindValue(currentUserId);

        int orderId = -1;
        if (qOrder.exec() && qOrder.next()) {
            orderId = qOrder.value(0).toInt();
        } else {
            db.rollback();
            emit productOperationResult(false, "Ошибка создания заказа: " + qOrder.lastError().text());
            return;
        }

        QString tableName = isKit ? "embroidery_kits" : "consumable_furniture";
        QString itemName = "Товар";
        QSqlQuery qName(db);
        qName.prepare("SELECT name FROM " + tableName + " WHERE id = ?");
        qName.addBindValue(productId);
        if (qName.exec() && qName.next()) {
            itemName = qName.value(0).toString();
        }

        QSqlQuery qItem(db);
        if (isKit) {
            qItem.prepare("INSERT INTO order_items (order_id, embroidery_kit_id, item_name, quantity, unit_price, total_price) VALUES (?, ?, ?, ?, ?, ?)");
        } else {
            qItem.prepare("INSERT INTO order_items (order_id, consumable_furniture_id, item_name, quantity, unit_price, total_price) VALUES (?, ?, ?, ?, ?, ?)");
        }

        qItem.addBindValue(orderId);
        qItem.addBindValue(productId);
        qItem.addBindValue(itemName);
        qItem.addBindValue(quantity);
        qItem.addBindValue(unitPrice);
        qItem.addBindValue(quantity * unitPrice);

        if (!qItem.exec()) {
            db.rollback();
            emit productOperationResult(false, "Ошибка добавления позиции: " + qItem.lastError().text());
            return;
        }

        QSqlQuery qStock(db);
        qStock.prepare("UPDATE " + tableName + " SET stock_quantity = stock_quantity - ? WHERE id = ?");
        qStock.addBindValue(quantity);
        qStock.addBindValue(productId);

        if (!qStock.exec()) {
            db.rollback();
            emit productOperationResult(false, "Ошибка списания: " + qStock.lastError().text());
            return;
        }

        if (db.commit()) {
            emit productOperationResult(true, "Продажа успешно оформлена");
            Logger::instance().log(QString::number(currentUserId), "ПРОДАЖИ", "ПРОДАЖА", itemName + " x" + QString::number(quantity));
        } else {
            db.rollback();
            emit productOperationResult(false, "Ошибка завершения транзакции");
        }
    });
}

/*!
 * \brief Асинхронно загружает заказы для текущего мастера.
 */
void DatabaseManager::fetchMasterOrdersAsync() {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;

        if (!db.isOpen()) {
            emit masterOrdersLoaded(result);
            return;
        }

        QSqlQuery query(db);
        QString queryStr = "SELECT "
                           "o.id, o.order_number, o.order_type, o.status, o.total_amount, o.created_at, "
                           "c.full_name as customer_name, c.phone as customer_phone, "
                           "fo.width, fo.height, fo.special_instructions, "
                           "fm.name as material_name, fm.color as material_color, "
                           "cf.name as furniture_name "
                           "FROM orders o "
                           "LEFT JOIN customers c ON o.customer_id = c.id "
                           "LEFT JOIN frame_orders fo ON o.id = fo.order_id "
                           "LEFT JOIN frame_materials fm ON fo.frame_material_id = fm.id "
                           "LEFT JOIN component_furniture cf ON fo.component_furniture_id = cf.id "
                           "WHERE o.order_type = 'Изготовление рамки' "
                           "AND (fo.master_id = ? OR fo.master_id IS NULL) "
                           "ORDER BY o.created_at DESC";

        query.prepare(queryStr);
        query.addBindValue(currentUserId);

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
            Logger::instance().log("Система", "МАСТЕР", "ОШИБКА_ДАННЫХ", query.lastError().text());
        }

        emit masterOrdersLoaded(result);
    });
}

/*!
 * \brief Асинхронно загружает список материалов для рам.
 */
void DatabaseManager::fetchMaterialsAsync(const QString &tableName) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;

        if (!db.isOpen()) {
            emit materialsLoaded(result);
            return;
        }

        if (tableName != "frame_materials" && tableName != "component_furniture") {
            emit materialsLoaded(result);
            return;
        }

        QSqlQuery query(db);
        QString sql = "SELECT * FROM " + tableName + " WHERE is_active = TRUE ORDER BY id DESC";

        if (query.exec(sql)) {
            while (query.next()) {
                QVariantMap row;
                QSqlRecord record = query.record();
                for (int i = 0; i < record.count(); ++i) {
                    row[record.fieldName(i)] = record.value(i);
                }
                result.append(row);
            }
        } else {
            Logger::instance().log("Система", "СКЛАД", "ОШИБКА_ДАННЫХ", query.lastError().text());
        }

        emit materialsLoaded(result);
    });
}

/*!
 * \brief Асинхронно добавляет новый материал для рам.
 */
void DatabaseManager::addFrameMaterialAsync(const QString &name, const QString &type, double price, double stock, const QString &color, double width) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit materialOperationResult(false, "Нет соединения");
            return;
        }

        QSqlQuery query(db);
        query.prepare("INSERT INTO frame_materials (name, type, price_per_meter, stock_quantity, color, width, created_by, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)");
        query.addBindValue(name);
        query.addBindValue(type);
        query.addBindValue(price);
        query.addBindValue(stock);
        query.addBindValue(color);
        query.addBindValue(width);
        query.addBindValue(currentUserId);

        if (query.exec()) {
            emit materialOperationResult(true, "Материал добавлен");
        } else {
            emit materialOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно обновляет материал для рам.
 */
void DatabaseManager::updateFrameMaterialAsync(int id, const QString &name, const QString &type, double price, double stock, const QString &color, double width) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit materialOperationResult(false, "Нет соединения");
            return;
        }

        QSqlQuery query(db);
        query.prepare("UPDATE frame_materials SET name = ?, type = ?, price_per_meter = ?, stock_quantity = ?, color = ?, width = ? WHERE id = ?");
        query.addBindValue(name);
        query.addBindValue(type);
        query.addBindValue(price);
        query.addBindValue(stock);
        query.addBindValue(color);
        query.addBindValue(width);
        query.addBindValue(id);

        if (query.exec()) {
            emit materialOperationResult(true, "Материал обновлен");
        } else {
            emit materialOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно удаляет (деактивирует) материал для рам.
 */
void DatabaseManager::deleteFrameMaterialAsync(int id) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit materialOperationResult(false, "Нет соединения");
            return;
        }

        QSqlQuery query(db);
        query.prepare("UPDATE frame_materials SET is_active = FALSE WHERE id = ?");
        query.addBindValue(id);

        if (query.exec()) {
            emit materialOperationResult(true, "Материал удален");
        } else {
            emit materialOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно добавляет комплектующую фурнитуру.
 */
void DatabaseManager::addComponentFurnitureAsync(const QString &name, const QString &type, double price, int stock) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit materialOperationResult(false, "Нет соединения");
            return;
        }

        QSqlQuery query(db);
        query.prepare("INSERT INTO component_furniture (name, type, price_per_unit, stock_quantity, created_by, is_active) VALUES (?, ?, ?, ?, ?, TRUE)");
        query.addBindValue(name);
        query.addBindValue(type);
        query.addBindValue(price);
        query.addBindValue(stock);
        query.addBindValue(currentUserId);

        if (query.exec()) {
            emit materialOperationResult(true, "Фурнитура добавлена");
        } else {
            emit materialOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно обновляет комплектующую фурнитуру.
 */
void DatabaseManager::updateComponentFurnitureAsync(int id, const QString &name, const QString &type, double price, int stock) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit materialOperationResult(false, "Нет соединения");
            return;
        }

        QSqlQuery query(db);
        query.prepare("UPDATE component_furniture SET name = ?, type = ?, price_per_unit = ?, stock_quantity = ? WHERE id = ?");
        query.addBindValue(name);
        query.addBindValue(type);
        query.addBindValue(price);
        query.addBindValue(stock);
        query.addBindValue(id);

        if (query.exec()) {
            emit materialOperationResult(true, "Фурнитура обновлена");
        } else {
            emit materialOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно удаляет (деактивирует) комплектующую фурнитуру.
 */
void DatabaseManager::deleteComponentFurnitureAsync(int id) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit materialOperationResult(false, "Нет соединения");
            return;
        }

        QSqlQuery query(db);
        query.prepare("UPDATE component_furniture SET is_active = FALSE WHERE id = ?");
        query.addBindValue(id);

        if (query.exec()) {
            emit materialOperationResult(true, "Фурнитура удалена");
        } else {
            emit materialOperationResult(false, query.lastError().text());
        }
    });
}

/*!
 * \brief Асинхронно загружает последние 1000 записей логов.
 */
void DatabaseManager::fetchLogs() {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;

        if (!db.isOpen()) {
            emit logsLoaded(result);
            return;
        }

        QSqlQuery query(db);
        query.prepare("SELECT * FROM event_logs ORDER BY timestamp DESC LIMIT 1000");

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
            Logger::instance().log("Система", "ДАННЫЕ", "ОШИБКА_ЛОГОВ", query.lastError().text());
        }

        emit logsLoaded(result);
    });
}

/*!
 * \brief Асинхронно подсчитывает общее количество записей в логах.
 */
void DatabaseManager::fetchLogsCount() {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QSqlQuery query(db);
        int count = 0;
        if (query.exec("SELECT COUNT(*) FROM event_logs") && query.next()) {
            count = query.value(0).toInt();
        }
        emit logsCountLoaded(count);
    });
}

/*!
 * \brief Асинхронно загружает логи за указанный период.
 */
void DatabaseManager::fetchLogsByPeriod(const QString &dateFrom, const QString &dateTo) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;

        if (!db.isOpen()) {
            emit logsLoaded(result);
            return;
        }

        QDate startDate = QDate::fromString(dateFrom, "dd.MM.yyyy");
        QDate endDate = QDate::fromString(dateTo, "dd.MM.yyyy");

        if (!startDate.isValid() || !endDate.isValid()) {
            emit logsLoaded(result);
            return;
        }

        QDateTime startDt = startDate.startOfDay();
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

        emit logsLoaded(result);
    });
}

/*!
 * \brief Асинхронно загружает статистику продаж за последние N дней.
 */
void DatabaseManager::fetchStatisticsAsync(int days) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        QVariantList result;

        if (!db.isOpen()) {
            emit statisticsLoaded(result);
            return;
        }

        QSqlQuery query(db);
        QString sql = QString(
                          "SELECT to_char(created_at, 'DD.MM') as date_label, "
                          "COUNT(id) as order_count, "
                          "COALESCE(SUM(total_amount), 0) as total_revenue "
                          "FROM orders "
                          "WHERE created_at >= CURRENT_DATE - INTERVAL '%1 days' "
                          "GROUP BY date_label, date_trunc('day', created_at) "
                          "ORDER BY date_trunc('day', created_at) ASC"
                          ).arg(days);

        if (query.exec(sql)) {
            while (query.next()) {
                QVariantMap item;
                item["date"] = query.value("date_label");
                item["count"] = query.value("order_count");
                item["revenue"] = query.value("total_revenue");
                result.append(item);
            }
        } else {
            Logger::instance().log("Система", "СТАТИСТИКА", "ОШИБКА", query.lastError().text());
        }

        emit statisticsLoaded(result);
    });
}

/*!
 * \brief Асинхронно экспортирует таблицу в формат CSV.
 */
void DatabaseManager::exportTableAsync(const QString &tableName, const QString &filePath) {
    auto future = QtConcurrent::run([=]() {
        if (!tables.contains(tableName)) {
            emit operationResult(false, "Экспорт запрещен");
            return;
        }

        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit operationResult(false, "Нет соединения с БД");
            return;
        }

        QString cleanPath = filePath;
        if (cleanPath.startsWith("file:///")) {
            cleanPath.remove(0, 8);
        } else if (cleanPath.startsWith("file://")) {
            cleanPath.remove(0, 7);
        }
        cleanPath = QDir::toNativeSeparators(cleanPath);

        QFile file(cleanPath);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            emit operationResult(false, "Не удалось создать файл");
            return;
        }

        QTextStream out(&file);
        out.setGenerateByteOrderMark(true);
        out.setEncoding(QStringConverter::Utf8);

        QSqlQuery query(db);
        if (!query.exec("SELECT * FROM " + tableName)) {
            file.close();
            emit operationResult(false, "Ошибка SQL");
            return;
        }

        const QString separator = ",";

        QSqlRecord record = query.record();
        QStringList headers;
        for (int i = 0; i < record.count(); ++i) {
            headers << "\"" + record.fieldName(i) + "\"";
        }
        out << headers.join(separator) << "\n";

        while (query.next()) {
            QStringList rowData;
            for (int i = 0; i < record.count(); ++i) {
                QString val = query.value(i).toString();
                val.replace("\"", "\"\"");
                rowData << "\"" + val + "\"";
            }
            out << rowData.join(separator) << "\n";
        }

        file.close();
        Logger::instance().log("Админ", "ЭКСПОРТ", "УСПЕХ", tableName);
        emit operationResult(true, "Экспорт завершен успешно");
    });
}

/*!
 * \brief Асинхронно импортирует данные из CSV файла в таблицу.
 */
void DatabaseManager::importTableAsync(const QString &tableName, const QString &filePath) {
    auto future = QtConcurrent::run([=]() {
        if (!tables.contains(tableName)) {
            emit operationResult(false, "Импорт в таблицу '" + tableName + "' запрещен");
            return;
        }

        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit operationResult(false, "Нет соединения с БД");
            return;
        }

        QString cleanPath = filePath;
        if (cleanPath.startsWith("file:///")) {
            cleanPath.remove(0, 8);
        } else if (cleanPath.startsWith("file://")) {
            cleanPath.remove(0, 7);
        }
        cleanPath = QDir::toNativeSeparators(cleanPath);

        QFile file(cleanPath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            emit operationResult(false, "Не удалось открыть файл:\n" + cleanPath);
            return;
        }

        QTextStream in(&file);
        in.setAutoDetectUnicode(true);

        QString headerLine = in.readLine();
        if (headerLine.isEmpty()) {
            emit operationResult(false, "Файл пуст");
            return;
        }

        QStringList columnsRaw = headerLine.split(",");
        QStringList columns;
        for (const QString &col : columnsRaw) {
            QString c = col.trimmed();
            if (c.startsWith('"')) {
                c.remove(0, 1);
            }
            if (c.endsWith('"')) {
                c.chop(1);
            }
            columns << c;
        }

        QStringList placeholders;
        for (int i = 0; i < columns.size(); ++i) {
            placeholders << "?";
        }
        QString sql = "INSERT INTO " + tableName + " (" + columns.join(", ") + ") VALUES (" + placeholders.join(", ") + ")";

        if (!db.transaction()) {
            emit operationResult(false, "Ошибка БД: Не удалось начать транзакцию");
            return;
        }

        QSqlQuery query(db);
        query.prepare(sql);

        int rowsImported = 0;
        int errors = 0;

        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.trimmed().isEmpty()) {
                continue;
            }

            QString cleanLine = line.trimmed();
            if (cleanLine.startsWith('"')) {
                cleanLine.remove(0, 1);
            }
            if (cleanLine.endsWith('"')) {
                cleanLine.chop(1);
            }

            QStringList values = cleanLine.split("\",\"");

            if (values.size() != columns.size()) {
                if (values.size() == 1 && cleanLine.contains(",")) {
                    values = cleanLine.split(",");
                }

                if (values.size() != columns.size()) {
                    errors++;
                    continue;
                }
            }

            for (const QString &val : values) {
                QString v = val;
                v.replace("\"\"", "\"");

                if (v == "NULL" || v.isEmpty()) {
                    query.addBindValue(QVariant(QVariant::String));
                } else {
                    query.addBindValue(v);
                }
            }

            if (!query.exec()) {
                errors++;
            } else {
                rowsImported++;
            }
        }

        if (rowsImported > 0) {
            db.commit();
            Logger::instance().log("Админ", "ИМПОРТ", "УСПЕХ", tableName + " +" + QString::number(rowsImported));
            emit operationResult(true, "Успешно импортировано строк: " + QString::number(rowsImported) +
                                           "\nПропущено/Ошибок: " + QString::number(errors));
        } else {
            db.rollback();
            emit operationResult(false, "Не удалось импортировать данные");
        }

        file.close();
    });
}

/*!
 * \brief Асинхронно создает полную резервную копию (дамп) базы данных.
 */
void DatabaseManager::createBackupAsync(const QString &filePath) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit operationResult(false, "Нет соединения с БД");
            return;
        }

        QString cleanPath = filePath;
        if (cleanPath.startsWith("file:///")) {
            cleanPath.remove(0, 8);
        } else if (cleanPath.startsWith("file://")) {
            cleanPath.remove(0, 7);
        }
        cleanPath = QDir::toNativeSeparators(cleanPath);

        QFile file(cleanPath);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            emit operationResult(false, "Не удалось создать файл бэкапа");
            return;
        }

        QTextStream out(&file);
        out.setEncoding(QStringConverter::Utf8);

        out << "-- Бэкап базы данных BagetWorkshop\n";
        out << "-- Дата: " << QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss") << "\n";
        out << "BEGIN;\n\n";

        out << "SET session_replication_role = 'replica';\n\n";

        const QStringList tablesToBackup = tables;

        QSqlQuery query(db);
        bool success = true;

        for (const QString &tableName : tablesToBackup) {
            out << "-- Таблица: " << tableName << "\n";
            out << "TRUNCATE TABLE " << tableName << " CASCADE;\n";

            if (!query.exec("SELECT * FROM " + tableName)) {
                Logger::instance().log("Админ", "БЭКАП", "ОШИБКА_ЧТЕНИЯ", tableName);
                continue;
            }

            QSqlRecord record = query.record();
            int colCount = record.count();

            if (query.size() == 0) {
                out << "\n";
                continue;
            }

            while (query.next()) {
                QStringList values;
                for (int i = 0; i < colCount; ++i) {
                    QVariant val = query.value(i);

                    if (val.isNull()) {
                        values << "NULL";
                    } else if (val.typeId() == QMetaType::QString ||
                               val.typeId() == QMetaType::QDate ||
                               val.typeId() == QMetaType::QDateTime ||
                               val.typeId() == QMetaType::QTime) {
                        QString str = val.toString();
                        str.replace("'", "''");
                        values << "'" + str + "'";
                    } else if (val.typeId() == QMetaType::Bool) {
                        values << (val.toBool() ? "TRUE" : "FALSE");
                    } else {
                        values << val.toString();
                    }
                }

                out << "INSERT INTO " << tableName << " VALUES (" << values.join(", ") << ");\n";
            }
            out << "\n";
        }

        out << "SET session_replication_role = 'origin';\n";
        out << "COMMIT;\n";

        file.close();

        Logger::instance().log("Админ", "БЭКАП", "УСПЕХ", "Ручной дамп создан: " + cleanPath);
        emit operationResult(true, "Резервная копия успешно создана");
    });
}

/*!
 * \brief Асинхронно восстанавливает базу данных из файла резервной копии.
 */
void DatabaseManager::restoreFromBackupAsync(const QString &filePath) {
    auto future = QtConcurrent::run([=]() {
        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit operationResult(false, "Нет соединения с БД");
            return;
        }

        QString cleanPath = filePath;
        if (cleanPath.startsWith("file:///")) {
            cleanPath.remove(0, 8);
        } else if (cleanPath.startsWith("file://")) {
            cleanPath.remove(0, 7);
        }
        cleanPath = QDir::toNativeSeparators(cleanPath);

        QFile file(cleanPath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            emit operationResult(false, "Не удалось открыть файл бэкапа");
            return;
        }

        QTextStream in(&file);
        in.setAutoDetectUnicode(true);
        QString sqlScript = in.readAll();
        file.close();

        if (sqlScript.isEmpty()) {
            emit operationResult(false, "Файл пуст");
            return;
        }

        QSqlQuery query(db);
        if (query.exec(sqlScript)) {
            Logger::instance().log("Админ", "ВОССТАНОВЛЕНИЕ", "УСПЕХ", "Файл: " + cleanPath);
            emit operationResult(true, "База успешно восстановлена");
        } else {
            QString err = query.lastError().text();
            Logger::instance().log("Админ", "ВОССТАНОВЛЕНИЕ", "ОШИБКА", err);
            emit operationResult(false, "Ошибка восстановления");
        }
    });
}

/*!
 * \brief Генерирует чек в формате PDF.
 * Использует QPdfWriter и QPainter для отрисовки документа.
 */
void DatabaseManager::generatePdfReceipt(int orderId, const QString &filePath) {
    auto future = QtConcurrent::run([=]() {
        QString cleanPath = filePath;
        if (cleanPath.startsWith("file:///")) {
            cleanPath.remove(0, 8);
        } else if (cleanPath.startsWith("file://")) {
            cleanPath.remove(0, 7);
        }
        cleanPath = QDir::toNativeSeparators(cleanPath);

        QSqlDatabase db = getThreadLocalConnection();
        if (!db.isOpen()) {
            emit pdfGenerated(false, "Нет соединения с базой данных");
            return;
        }

        QSqlQuery orderQuery(db);
        QString orderSql = "SELECT o.order_number, o.created_at, o.total_amount, o.order_type, "
                           "c.full_name, c.phone, c.email "
                           "FROM orders o "
                           "LEFT JOIN customers c ON o.customer_id = c.id "
                           "WHERE o.id = ?";
        orderQuery.prepare(orderSql);
        orderQuery.addBindValue(orderId);

        if (!orderQuery.exec() || !orderQuery.next()) {
            emit pdfGenerated(false, "Заказ не найден");
            return;
        }

        QString orderNumber = orderQuery.value("order_number").toString();
        QString dateStr = orderQuery.value("created_at").toDateTime().toString("dd.MM.yyyy HH:mm");
        double totalAmount = orderQuery.value("total_amount").toDouble();
        QString orderType = orderQuery.value("order_type").toString();
        QString customerName = orderQuery.value("full_name").toString();
        QString customerPhone = orderQuery.value("phone").toString();
        QString customerEmail = orderQuery.value("email").toString();

        QPdfWriter writer(cleanPath);
        writer.setResolution(96);
        writer.setPageSize(QPageSize(QPageSize::A4));
        writer.setPageMargins(QMarginsF(15, 15, 15, 15));
        writer.setTitle("Check " + orderNumber);

        QPainter painter(&writer);

        QFont titleFont("Arial", 13, QFont::Bold);
        QFont headerFont("Arial", 12, QFont::Bold);
        QFont bodyFont("Arial", 11);
        QFont smallFont("Arial", 9);

        int pageWidth = writer.width();
        int y = 0;
        int lineHeight = 35;

        painter.setFont(titleFont);
        painter.drawText(QRect(0, y, pageWidth, 40), Qt::AlignCenter, "БАГЕТНАЯ МАСТЕРСКАЯ");
        y += 50;

        painter.setFont(headerFont);
        painter.drawText(QRect(0, y, pageWidth, 30), Qt::AlignCenter, "ТОВАРНЫЙ ЧЕК");
        y += 40;

        painter.setFont(smallFont);
        painter.drawText(QRect(0, y, pageWidth, 20), Qt::AlignCenter, "ИП Иванов И.И. | г. Ейск, ул. Коммунистическая, д. 83/3");
        y += 20;
        painter.drawText(QRect(0, y, pageWidth, 20), Qt::AlignCenter, "Тел: +7 (999) 999-99-99 | baget@mail.ru");
        y += 40;

        QPen pen;
        pen.setWidth(2);
        painter.setPen(pen);
        painter.drawLine(0, y, pageWidth, y);
        y += 30;

        painter.setFont(bodyFont);

        int rowHeight = 20;
        int rowStep = 30;

        painter.drawText(QRect(0, y, pageWidth / 2, rowHeight), Qt::AlignLeft, "Заказ №: " + orderNumber);
        painter.drawText(QRect(pageWidth / 2, y, pageWidth / 2, rowHeight), Qt::AlignRight, "Клиент: " + customerName);
        y += rowStep;

        painter.drawText(QRect(0, y, pageWidth / 2, rowHeight), Qt::AlignLeft, "Дата: " + dateStr);
        painter.drawText(QRect(pageWidth / 2, y, pageWidth / 2, rowHeight), Qt::AlignRight, "Телефон: " + customerPhone);
        y += rowStep;

        painter.drawText(QRect(0, y, pageWidth / 2, rowHeight), Qt::AlignLeft, "Тип: " + orderType);
        painter.drawText(QRect(pageWidth / 2, y, pageWidth / 2, rowHeight), Qt::AlignRight, "Email: " + customerEmail);
        y += rowStep;

        y += 40;

        painter.setFont(headerFont);

        int col1 = 0;
        int col2 = pageWidth * 0.55;
        int col3 = pageWidth * 0.70;
        int col4 = pageWidth * 0.85;

        painter.fillRect(QRect(0, y, pageWidth, 30), QColor(240, 240, 240));

        painter.drawText(QRect(col1 + 5, y, col2 - col1, 30), Qt::AlignLeft | Qt::AlignVCenter, "Наименование");
        painter.drawText(QRect(col2, y, col3 - col2, 30), Qt::AlignCenter | Qt::AlignVCenter, "Кол-во");
        painter.drawText(QRect(col3, y, col4 - col3, 30), Qt::AlignRight | Qt::AlignVCenter, "Цена");
        painter.drawText(QRect(col4, y, pageWidth - col4 - 5, 30), Qt::AlignRight | Qt::AlignVCenter, "Сумма");

        y += 40;
        painter.drawLine(0, y, pageWidth, y);
        y += 20;

        painter.setFont(bodyFont);

        if (orderType == "Изготовление рамки") {
            QSqlQuery frameQuery(db);
            frameQuery.prepare("SELECT fo.width, fo.height, fo.selling_price, "
                               "fm.name as mat_name, cf.name as furn_name "
                               "FROM frame_orders fo "
                               "LEFT JOIN frame_materials fm ON fo.frame_material_id = fm.id "
                               "LEFT JOIN component_furniture cf ON fo.component_furniture_id = cf.id "
                               "WHERE fo.order_id = ?");
            frameQuery.addBindValue(orderId);

            if (frameQuery.exec() && frameQuery.next()) {
                QString matName = frameQuery.value("mat_name").toString();
                QString furnName = frameQuery.value("furn_name").toString();
                double w = frameQuery.value("width").toDouble();
                double h = frameQuery.value("height").toDouble();
                double price = frameQuery.value("selling_price").toDouble();

                int itemRowStep = 25;

                painter.drawText(QRect(col1, y, col2 - col1, 25), Qt::AlignLeft, QString("Рамка %1 x %2 см").arg(w).arg(h));
                painter.drawText(QRect(col1, y + itemRowStep, col2 - col1, 25), Qt::AlignLeft, "Багет: " + matName);
                painter.drawText(QRect(col1, y + itemRowStep * 2, col2 - col1, 25), Qt::AlignLeft, "Фурнитура: " + furnName);

                int blockHeight = itemRowStep * 3;

                painter.drawText(QRect(col2, y, col3 - col2, blockHeight), Qt::AlignCenter | Qt::AlignVCenter, "1");
                painter.drawText(QRect(col3, y, col4 - col3, blockHeight), Qt::AlignRight | Qt::AlignVCenter, QString::number(price, 'f', 2));
                painter.drawText(QRect(col4, y, pageWidth - col4, blockHeight), Qt::AlignRight | Qt::AlignVCenter, QString::number(price, 'f', 2));

                y += blockHeight + 20;
            }

        } else {
            QSqlQuery itemsQuery(db);
            itemsQuery.prepare("SELECT item_name, quantity, unit_price, total_price FROM order_items WHERE order_id = ?");
            itemsQuery.addBindValue(orderId);

            if (itemsQuery.exec()) {
                while (itemsQuery.next()) {
                    QString name = itemsQuery.value("item_name").toString();
                    int qty = itemsQuery.value("quantity").toInt();
                    double price = itemsQuery.value("unit_price").toDouble();
                    double total = itemsQuery.value("total_price").toDouble();

                    painter.drawText(QRect(col1, y, col2 - col1, lineHeight), Qt::AlignLeft | Qt::AlignVCenter, name);
                    painter.drawText(QRect(col2, y, col3 - col2, lineHeight), Qt::AlignCenter | Qt::AlignVCenter, QString::number(qty));
                    painter.drawText(QRect(col3, y, col4 - col3, lineHeight), Qt::AlignRight | Qt::AlignVCenter, QString::number(price, 'f', 2));
                    painter.drawText(QRect(col4, y, pageWidth - col4, lineHeight), Qt::AlignRight | Qt::AlignVCenter, QString::number(total, 'f', 2));

                    y += lineHeight;
                }
            }
        }

        y += 10;
        painter.drawLine(0, y, pageWidth, y);

        y += 40;

        painter.setFont(titleFont);
        QString totalText = "ИТОГО К ОПЛАТЕ: " + QString::number(totalAmount, 'f', 2) + " RUB";
        painter.drawText(QRect(0, y, pageWidth, 40), Qt::AlignRight, totalText);

        y += 80;

        painter.setFont(bodyFont);

        painter.drawText(QRect(0, y, pageWidth, 20), Qt::AlignLeft, "Подпись продавца: _________________________");
        y += 60;
        painter.drawText(QRect(0, y, pageWidth, 20), Qt::AlignLeft, "Подпись клиента:   _________________________");

        y += 80;

        QFont footerFont = bodyFont;
        footerFont.setItalic(true);
        painter.setFont(footerFont);
        painter.drawText(QRect(0, y, pageWidth, 30), Qt::AlignCenter, "Благодарим за покупку!");

        painter.end();

        emit pdfGenerated(true, cleanPath);
        Logger::instance().log(QString::number(currentUserId), "ПЕЧАТЬ", "PDF_СОЗДАН", "Файл: " + cleanPath);
    });
}
