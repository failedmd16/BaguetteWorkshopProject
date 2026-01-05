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
#include <QtConcurrent>
#include <QSqlField>
#include <QVariant>
#include <QThread>
#include <QPdfWriter>
#include <QPainter>
#include <QPageSize>
#include <QPageLayout>
#include <QTextDocument>
#include "Logger.h"

/*!
 * \brief Класс DatabaseManager управляет подключением к базе данных и выполняет операции с данными.
 *
 * Реализует паттерн Singleton. Все методы работы с БД выполняются асинхронно
 * в отдельных потоках, чтобы не блокировать GUI.
 */
class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    static DatabaseManager* instance();
    static void destroyInstance();

    Q_INVOKABLE void loginUserAsync(const QString &login, const QString &password);
    Q_INVOKABLE void registerUserAsync(const QString &login, const QString &password, const QString &role);
    Q_INVOKABLE void updateUserPasswordAsync(const QString &login, const QString &newPassword);

    Q_INVOKABLE int getCurrentUserID();
    Q_INVOKABLE QString getCurrentUserRole() const;

    Q_INVOKABLE bool hasAdminAccount();
    Q_INVOKABLE void createFirstAdminAsync(const QString &login, const QString &password);

    Q_INVOKABLE int getRetailCustomerId();
    Q_INVOKABLE void fetchCustomers();
    Q_INVOKABLE void addCustomerAsync(const QString &name, const QString &phone, const QString &email, const QString &address);
    Q_INVOKABLE void updateCustomerAsync(int id, const QString &name, const QString &phone, const QString &email, const QString &address);
    Q_INVOKABLE void deleteCustomerAsync(int id);
    Q_INVOKABLE void fetchCustomerOrdersAsync(int customerId);

    Q_INVOKABLE void fetchReportAsync(const QString &startDate, const QString &endDate);
    Q_INVOKABLE void fetchOrders();
    Q_INVOKABLE void fetchReferenceData();

    Q_INVOKABLE void createOrderTransactionAsync(const QVariantMap &data);
    Q_INVOKABLE void updateOrderAsync(int id, const QString &status, double amount, const QString &notes);
    Q_INVOKABLE void deleteOrderAsync(int id);

    Q_INVOKABLE void updateOrderStatusAsync(int id, const QString &newStatus);
    Q_INVOKABLE void fetchProductsAsync(bool isKit);

    Q_INVOKABLE void addEmbroideryKitAsync(const QString &name, const QString &description, double price, int quantity);
    Q_INVOKABLE void updateEmbroideryKitAsync(int id, const QString &name, const QString &description, double price, int quantity);
    Q_INVOKABLE void deleteEmbroideryKitAsync(int id);

    Q_INVOKABLE void addConsumableAsync(const QString &name, const QString &type, double price, int quantity, const QString &unit);
    Q_INVOKABLE void updateConsumableAsync(int id, const QString &name, const QString &type, double price, int quantity, const QString &unit);
    Q_INVOKABLE void deleteConsumableAsync(int id);

    Q_INVOKABLE void processRetailSaleAsync(int productId, bool isKit, int quantity, double unitPrice);

    Q_INVOKABLE void fetchMaterialsAsync(const QString &tableName);

    Q_INVOKABLE void addFrameMaterialAsync(const QString &name, const QString &type, double price, double stock, const QString &color, double width);
    Q_INVOKABLE void updateFrameMaterialAsync(int id, const QString &name, const QString &type, double price, double stock, const QString &color, double width);
    Q_INVOKABLE void deleteFrameMaterialAsync(int id);

    Q_INVOKABLE void addComponentFurnitureAsync(const QString &name, const QString &type, double price, int stock);
    Q_INVOKABLE void updateComponentFurnitureAsync(int id, const QString &name, const QString &type, double price, int stock);
    Q_INVOKABLE void deleteComponentFurnitureAsync(int id);

    Q_INVOKABLE void fetchMasterOrdersAsync();

    Q_INVOKABLE void fetchLogs();
    Q_INVOKABLE void fetchLogsCount();
    Q_INVOKABLE void fetchLogsByPeriod(const QString &dateFrom, const QString &dateTo);
    Q_INVOKABLE void fetchStatisticsAsync(int days);

    Q_INVOKABLE void exportTableAsync(const QString &tableName, const QString &filePath);
    Q_INVOKABLE void importTableAsync(const QString &tableName, const QString &filePath);

    Q_INVOKABLE void createBackupAsync(const QString &filePath);
    Q_INVOKABLE void restoreFromBackupAsync(const QString &filePath);

    Q_INVOKABLE void generatePdfReceipt(int orderId, const QString &filePath);

signals:
    void loginResult(bool success, QString role, QString message);
    void firstAdminCreatedResult(bool success, QString message);
    void userOperationResult(bool success, QString message);

    void customersLoaded(QVariantList data);
    void customerOrdersLoaded(QVariantList data);
    void reportDataLoaded(QVariantList data);
    void customerOperationResult(bool success, QString message);

    void ordersLoaded(const QVariantList &data);
    void referenceDataLoaded(const QVariantMap &data);
    void orderOperationResult(bool success, const QString &message);
    void statusUpdateResult(bool success, QString message);

    void productsLoaded(QVariantList data);
    void productOperationResult(bool success, QString message);

    void masterOrdersLoaded(QVariantList data);

    void materialsLoaded(QVariantList data);
    void materialOperationResult(bool success, QString message);

    void logsLoaded(QVariantList logs);
    void logsCountLoaded(int count);

    void statisticsLoaded(QVariantList data);
    void operationResult(bool success, QString message);

    void pdfGenerated(bool success, QString pathOrMessage);

private:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();
    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;

    static QMutex m_connectionMutex;

    bool initializeDatabase();
    void createTables();
    QString hashPassword(const QString &password);
    bool validateLogin(const QString &login);
    bool validatePassword(const QString &password);
    QSqlDatabase getThreadLocalConnection();

    static DatabaseManager* m_instance;
    static QMutex m_mutex;
    QSqlDatabase _database;

    int currentUserId = -1;
    QString currentUserRole;

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
