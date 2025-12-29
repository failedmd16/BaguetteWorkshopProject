#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlRecord>
#include <QtSql/QSqlError>
#include <QtSql/QSqlQueryModel>
#include <QCryptographicHash>
#include <QVariantMap>
#include <QDebug>
#include <QDir>
#include <QMutex>

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    static DatabaseManager* instance();
    static void destroyInstance();

public:
    Q_INVOKABLE bool initializeDatabase();

    Q_INVOKABLE bool loginUser(const QString &login, const QString &password);

    Q_INVOKABLE int getCurrentUserID(); // Получить айди текущего пользователя

    Q_INVOKABLE QString getCurrentUserRole() const; // Получить роль текущего пользователя

    Q_INVOKABLE QSqlQueryModel* getTableModel(const QString &table); // модель данных таблицы "Клиенты". Остальные табл. по такому же принципу делаются

    Q_INVOKABLE QVariantMap getRowData(const QString &table, int row); // Получение данных конкретной строки

    Q_INVOKABLE int getRowCount(const QString &table); // Количество записей в таблице

    // Добавление нового покупателя
    Q_INVOKABLE void addCustomer(const QString &name, const QString &email, const QString &phone, const QString &address);

    // Редактирование информации о покупателе
    Q_INVOKABLE void updateCustomer(int row, const QString &name, const QString &email, const QString &phone, const QString &address);

    // Удаление покупателя
    Q_INVOKABLE void deleteCustomer(int row);

    Q_INVOKABLE QVariantList getCustomersWithOrdersInPeriod(const QString &startDate, const QString &endDate);

    Q_INVOKABLE QVariantList getCustomerOrders(int customerId); // Получить списком заказы покупателя для вывода в окне CustomersPage

    Q_INVOKABLE QSqlQueryModel* getCustomersModel(); // Получить всех клиентов для ComboBox

    Q_INVOKABLE QSqlQueryModel* getEmbroideryKitsModel(); // Получить все наборы для вышивки

    // Создать новый заказ
    Q_INVOKABLE bool createOrder(const QString &orderNumber, int customerId, const QString &orderType, double totalAmount, const QString &status = "new", const QString &notes = "");

    // Создать заказ на рамку
    Q_INVOKABLE bool createFrameOrder(int orderId, double width, double height, int frameMaterialId = 1, int componentFurnitureId = 1, const QString &specialInstructions = "");

    // Создать позицию заказа для набора
    Q_INVOKABLE bool createOrderItem(int orderId, int itemId, const QString &itemType, int quantity, double unitPrice);

    Q_INVOKABLE bool updateOrderStatus(int orderId, const QString &newStatus); // Обновить статус заказа

    Q_INVOKABLE QSqlQueryModel* getFrameMaterialsModel();

    Q_INVOKABLE void addFrameMaterial(const QString &name, const QString &type, double pricePerMeter,
                                      double stockQuantity, const QString &color, double width);

    Q_INVOKABLE void updateFrameMaterial(int row, const QString &name, const QString &type,
                                         double pricePerMeter, double stockQuantity, const QString &color, double width);

    Q_INVOKABLE void deleteFrameMaterial(int row);

    Q_INVOKABLE QSqlQueryModel* getComponentFurnitureModel();

    Q_INVOKABLE void addComponentFurniture(const QString &name, const QString &type,
                                           double pricePerUnit, int stockQuantity);

    Q_INVOKABLE void updateComponentFurniture(int row, const QString &name, const QString &type,
                                              double pricePerUnit, int stockQuantity);

    Q_INVOKABLE void deleteComponentFurniture(int row);

    Q_INVOKABLE void addEmbroideryKit(const QString &name, const QString &description, double price, int stockQuantity);

    Q_INVOKABLE void addConsumableFurniture(const QString &name, const QString &type, double pricePerUnit, int stockQuantity, const QString &unit);

    Q_INVOKABLE QVariantList getOrdersData();

    Q_INVOKABLE void updateEmbroideryKitStock(int id, int newQuantity);

    Q_INVOKABLE void updateConsumableStock(int id, int newQuantity);

    Q_INVOKABLE void updateEmbroideryKit(int id, const QString &name, const QString &description,
                                         double price, int stockQuantity);

    Q_INVOKABLE void updateConsumableFurniture(int id, const QString &name, const QString &type,
                                               double pricePerUnit, int stockQuantity, const QString &unit);

    Q_INVOKABLE void deleteEmbroideryKit(int id);

    Q_INVOKABLE void deleteConsumableFurniture(int id);

    Q_INVOKABLE int getLastInsertedOrderId();

    Q_INVOKABLE QVariantList getMasterOrdersData();

    bool isConnected() const;

private:
    DatabaseManager(QObject *parent = nullptr);
    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;
    ~DatabaseManager();

    static DatabaseManager* m_instance;
    static QMutex m_mutex;
    QSqlDatabase _database;

    int currentUserId;
    QString currentUserRole;
};

#endif // DATABASEMANAGER_H
