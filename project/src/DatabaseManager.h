#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
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
    void createTables();
    void insertTestData();

    Q_INVOKABLE bool loginUser(const QString &login, const QString &password);

    Q_INVOKABLE QString getCurrentUserRole() const;
    Q_INVOKABLE int getCurrentUserId() const;
    Q_INVOKABLE bool isSeller() const;
    Q_INVOKABLE bool isMaster() const;

private:
    QSqlDatabase _database;
    int currentUserId = -1;
    QString currentUserRole;
};

#endif // DATABASEMANAGER_H
