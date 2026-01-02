#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRecord>
#include <QDebug>
#include <QSqlQueryModel>
#include <QMutex>
#include <QCryptographicHash>
#include <QRegularExpression>
#include <QtConcurrent>  // Для QtConcurrent::run
#include <QSqlRecord>    // Для query.record()
#include <QSqlField>     // Для работы с полями записи (иногда нужно, если query.value() не хватает)
#include <QVariant>  // Для QVariantMap и QVariantList
#include <QThread>
#include "Logger.h"

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    static DatabaseManager* instance();
    static void destroyInstance();

    // Методы управления аккаунтами
    Q_INVOKABLE bool loginUser(const QString &login, const QString &password);
    Q_INVOKABLE bool registrationUser(const QString &login, const QString &password, const QString &role);
    Q_INVOKABLE bool updateUserPassword(const QString &login, const QString &newPassword);
    Q_INVOKABLE bool deleteUser(const QString &login);

    Q_INVOKABLE int getCurrentUserID();
    Q_INVOKABLE QString getCurrentUserRole() const;

    // Общие методы работы с таблицами
    Q_INVOKABLE QSqlQueryModel* getTableModel(const QString &name);
    Q_INVOKABLE QVariantMap getRowData(const QString &table, int row);
    Q_INVOKABLE int getRowCount(const QString &table);

    // Покупатели
    Q_INVOKABLE void addCustomer(const QString &name, const QString &phone, const QString &email, const QString &address);
    Q_INVOKABLE void updateCustomer(int row, const QString &name, const QString &phone, const QString &email, const QString &address);
    Q_INVOKABLE void deleteCustomer(int row);
    Q_INVOKABLE QSqlQueryModel* getCustomersModel();
    Q_INVOKABLE QVariantList getCustomersWithOrdersInPeriod(const QString &startDate, const QString &endDate);
    Q_INVOKABLE int getRetailCustomerId(); // <--- НОВЫЙ МЕТОД

    // Товары (Наборы и фурнитура)
    Q_INVOKABLE void addEmbroideryKit(const QString &name, const QString &description, double price, int stockQuantity);
    Q_INVOKABLE void updateEmbroideryKit(int id, const QString &name, const QString &description, double price, int stockQuantity);
    Q_INVOKABLE void deleteEmbroideryKit(int id);
    Q_INVOKABLE void updateEmbroideryKitStock(int id, int newQuantity);
    Q_INVOKABLE QSqlQueryModel* getEmbroideryKitsModel();

    Q_INVOKABLE void addConsumableFurniture(const QString &name, const QString &type, double pricePerUnit, int stockQuantity, const QString &unit);
    Q_INVOKABLE void updateConsumableFurniture(int id, const QString &name, const QString &type, double pricePerUnit, int stockQuantity, const QString &unit);
    Q_INVOKABLE void deleteConsumableFurniture(int id);
    Q_INVOKABLE void updateConsumableStock(int id, int newQuantity);

    // Материалы (Для мастера)
    Q_INVOKABLE void addFrameMaterial(const QString &name, const QString &type, double pricePerMeter, double stockQuantity, const QString &color, double width);
    Q_INVOKABLE void updateFrameMaterial(int row, const QString &name, const QString &type, double pricePerMeter, double stockQuantity, const QString &color, double width);
    Q_INVOKABLE void deleteFrameMaterial(int row);
    Q_INVOKABLE QSqlQueryModel* getFrameMaterialsModel();

    Q_INVOKABLE void addComponentFurniture(const QString &name, const QString &type, double pricePerUnit, int stockQuantity);
    Q_INVOKABLE void updateComponentFurniture(int row, const QString &name, const QString &type, double pricePerUnit, int stockQuantity);
    Q_INVOKABLE void deleteComponentFurniture(int row);
    Q_INVOKABLE QSqlQueryModel* getComponentFurnitureModel();

    // Заказы
    Q_INVOKABLE int createOrder(const QString &orderNumber, int customerId, const QString &orderType, double totalAmount, const QString &status, const QString &notes);
    Q_INVOKABLE void updateOrder(int id, const QString &status, double totalAmount, const QString &notes);
    Q_INVOKABLE void deleteOrder(int id);

    Q_INVOKABLE bool createFrameOrder(int orderId, double width, double height, int frameMaterialId, int componentFurnitureId, int masterId, const QString &specialInstructions);

    Q_INVOKABLE bool createOrderItem(int orderId, int itemId, const QString &itemType, const QString &itemName, int quantity, double unitPrice);
    Q_INVOKABLE bool updateOrderStatus(int orderId, const QString &newStatus);
    Q_INVOKABLE QVariantList getOrdersData();
    Q_INVOKABLE QVariantList getCustomerOrders(int customerId);

    // Мастер
    Q_INVOKABLE QVariantList getMasterOrdersData();
    Q_INVOKABLE QSqlQueryModel* getMastersModel();

    Q_INVOKABLE int getLastInsertedOrderId();

    // Администратор
    Q_INVOKABLE bool hasAdminAccount();
    Q_INVOKABLE bool createFirstAdmin(const QString &login, const QString &password);

    // Логи
    Q_INVOKABLE void fetchLogs();
    Q_INVOKABLE void fetchLogsCount();
    Q_INVOKABLE void fetchLogsByPeriod(const QString &dateFrom, const QString &dateTo);

    // Управление аккаунтами
    Q_INVOKABLE void registerUserAsync(const QString &login, const QString &password, const QString &role);
    Q_INVOKABLE void updateUserPasswordAsync(const QString &login, const QString &newPassword);
    Q_INVOKABLE void deleteUserAsync(const QString &login);

    // Клиенты
    Q_INVOKABLE void fetchCustomers();
    Q_INVOKABLE void addCustomerAsync(const QString &name, const QString &phone, const QString &email, const QString &address);
    Q_INVOKABLE void updateCustomerAsync(int id, const QString &name, const QString &phone, const QString &email, const QString &address);
    Q_INVOKABLE void deleteCustomerAsync(int id);
    Q_INVOKABLE void fetchCustomerOrdersAsync(int customerId);
    Q_INVOKABLE void fetchReportAsync(const QString &startDate, const QString &endDate);

    // Заказы
    Q_INVOKABLE void fetchOrders();
    Q_INVOKABLE void fetchReferenceData(); // Загрузит списки для ComboBox

    // Создание заказа одной транзакцией (принимает Map со всеми данными)
    Q_INVOKABLE void createOrderTransactionAsync(const QVariantMap &orderData);

    Q_INVOKABLE void updateOrderAsync(int id, const QString &status, double amount, const QString &notes);
    Q_INVOKABLE void deleteOrderAsync(int id);

signals:
    // Логи
    void logsLoaded(QVariantList logs);
    void logsCountLoaded(int count);

    // Управление аккаунтами
    void userOperationResult(bool success, QString message);

    // Клиенты
    void customersLoaded(QVariantList data);       // Основной список
    void customerOrdersLoaded(QVariantList data);  // История заказов одного клиента
    void reportDataLoaded(QVariantList data);      // Отчет фильтрации
    void customerOperationResult(bool success, QString message); // Результат (добавление/удаление)

    // Заказы
    void ordersLoaded(QVariantList data);
    void referenceDataLoaded(QVariantMap data); // Загрузка справочников (клиенты, материалы, наборы, мастера) одним пакетом
    void orderOperationResult(bool success, QString message);

    // Продажи


    // Заказы от лица мастера


    // Материалы от лица мастера

private:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();
    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;

    bool initializeDatabase();
    void createTables();
    void insertTestData();
    QString hashPassword(const QString &password);
    bool validateLogin(const QString &login);
    bool validatePassword(const QString &password);

    static DatabaseManager* m_instance;
    static QMutex m_mutex;
    QSqlDatabase _database;

    int currentUserId = -1;
    QString currentUserRole;

    QSqlDatabase getThreadLocalConnection();

    // Параметры для клонирования соединения
    struct DbParams {
        QString host;
        QString name;
        QString user;
        QString pass;
        int port;
        QString options;
    } m_dbParams;
};

#endif // DATABASEMANAGER_H
