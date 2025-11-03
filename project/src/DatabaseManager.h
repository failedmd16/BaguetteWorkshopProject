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

    Q_INVOKABLE bool initializeDatabase();

    Q_INVOKABLE bool loginUser(const QString &login, const QString &password);

    Q_INVOKABLE QString getCurrentUserRole() const;
    Q_INVOKABLE int getCurrentUserId() const;
    Q_INVOKABLE bool isSeller() const;
    Q_INVOKABLE bool isMaster() const;

    Q_INVOKABLE QSqlQueryModel* getTableModel(const QString &table); // модель данных таблицы "Клиенты". Остальные табл. по такому же принципу делаются

    Q_INVOKABLE QString getColumnName(const QString &table, int index);

private:
    QSqlDatabase _database;
    int currentUserId = -1;
    QString currentUserRole;

    void createTables();
    void insertTestData();
};

#endif // DATABASEMANAGER_H
