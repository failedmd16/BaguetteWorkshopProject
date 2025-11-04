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

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

public slots:
    Q_INVOKABLE bool initializeDatabase();

    Q_INVOKABLE bool loginUser(const QString &login, const QString &password);

    Q_INVOKABLE QString getCurrentUserRole() const; // Получить роль текущего пользователя
    Q_INVOKABLE int getCurrentUserId() const; // Получить ID текущего пользователя
    Q_INVOKABLE bool isSeller() const;
    Q_INVOKABLE bool isMaster() const;

    Q_INVOKABLE QSqlQueryModel* getTableModel(const QString &table); // модель данных таблицы "Клиенты". Остальные табл. по такому же принципу делаются

    Q_INVOKABLE QString getColumnName(const QString &table, int index); // Получить имя столбца в таблице для вывода в TableView
    Q_INVOKABLE QVariantMap getRowData(const QString &table, int row); // Получение данных конкретной строки

    Q_INVOKABLE int getRowCount(const QString &table); // Количество записей в таблице
    Q_INVOKABLE int getColumnCount(const QString &table); // Количество столбцов в таблице

    // Добавление нового покупателя
    Q_INVOKABLE void addCustomer(const QString &name, const QString &email, const QString &phone, const QString &address);
    // Редактирование информации о покупателе
    Q_INVOKABLE void updateCustomer(int row, const QString &name, const QString &email, const QString &phone, const QString &address);
    // Удаление покупателя
    Q_INVOKABLE void deleteCustomer(int row);

    Q_INVOKABLE QSqlQueryModel* getCustomersByPeriod(const QString& startDate, const QString& endDate); // Получить модель со всеми покупателями за указанный период
    Q_INVOKABLE QVariantList getCustomerOrders(int customerId); // Получить списком заказы покупателя для вывода в окне CustomersPage

    Q_INVOKABLE QSqlQueryModel* getCustomersModel(); // Получить всех клиентов для ComboBox

    Q_INVOKABLE QSqlQueryModel* getEmbroideryKitsModel(); // Получить все наборы для вышивки

    // Создать новый заказ
    Q_INVOKABLE bool createOrder(const QString &orderNumber, int customerId, const QString &orderType, double totalAmount, const QString &status = "new", const QString &notes = "");

    // Создать заказ на рамку
    Q_INVOKABLE bool createFrameOrder(int orderId, double width, double height, int frameMaterialId = 1, int componentFurnitureId = 1, const QString &specialInstructions = "");

    // Создать позицию заказа для набора
    Q_INVOKABLE bool createOrderItem(int orderId, int itemId, const QString &itemType, int quantity, double unitPrice);

    // Получить заказы с информацией о клиентах
    Q_INVOKABLE QSqlQueryModel* getOrdersWithCustomers();

    // Получить ID последнего вставленного заказа
    Q_INVOKABLE int getLastInsertedOrderId();

    // MastersOrdersPage функции
    Q_INVOKABLE QSqlQueryModel* getMasterOrders(); // Получить заказы для мастера
    Q_INVOKABLE bool updateOrderStatus(int orderId, const QString &newStatus); // Обновить статус заказа
    Q_INVOKABLE QVariantMap getOrderDetails(int orderId); // Получить детали заказа

    // MastersProductsPage функции
    // Функции для материалов рамок
    Q_INVOKABLE QSqlQueryModel* getFrameMaterialsModel();
    Q_INVOKABLE void addFrameMaterial(const QString &name, const QString &type, double pricePerMeter,
                                      double stockQuantity, const QString &color, double width);
    Q_INVOKABLE void updateFrameMaterial(int row, const QString &name, const QString &type,
                                         double pricePerMeter, double stockQuantity, const QString &color, double width);
    Q_INVOKABLE void deleteFrameMaterial(int row);
    Q_INVOKABLE QVariantMap getFrameMaterialRowData(int row);

    // Функции для комплектующей фурнитуры
    Q_INVOKABLE QSqlQueryModel* getComponentFurnitureModel();
    Q_INVOKABLE void addComponentFurniture(const QString &name, const QString &type,
                                           double pricePerUnit, int stockQuantity);
    Q_INVOKABLE void updateComponentFurniture(int row, const QString &name, const QString &type,
                                              double pricePerUnit, int stockQuantity);
    Q_INVOKABLE void deleteComponentFurniture(int row);
    Q_INVOKABLE QVariantMap getComponentFurnitureRowData(int row);

    Q_INVOKABLE QSqlQueryModel* getConsumableFurnitureModel();

    Q_INVOKABLE void addEmbroideryKit(const QString &name, const QString &description, double price, int stockQuantity);

    Q_INVOKABLE void addConsumableFurniture(const QString &name, const QString &type, double pricePerUnit, int stockQuantity, const QString &unit);

    Q_INVOKABLE QVariantList getOrdersData();

private:
    QSqlDatabase _database;
    int currentUserId = -1;
    QString currentUserRole;

    void createTables();
    void insertTestData();
};

#endif // DATABASEMANAGER_H
