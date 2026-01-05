#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QThread>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QDebug>
#include <QVariant>

/*!
 * \brief Класс, выполняющий запись логов в базу данных.
 *
 * Класс работает в отдельном потоке
 */
class LogWorker : public QObject
{
    Q_OBJECT
public:
    explicit LogWorker(QObject *parent = nullptr) : QObject(parent) { }
    ~LogWorker();

public slots:
    void processLog(const QString &timestamp, const QString &user, const QString &category, const QString &action, const QString &description);

private:
    void connectToDatabase();
    QSqlDatabase getDatabase();

    const QString m_connectionName = "AsyncLoggerConnection";
};

class Logger : public QObject
{
    Q_OBJECT
public:
    static Logger& instance();

    Q_INVOKABLE void log(const QString &user, const QString &category, const QString &action, const QString &description);

signals:
    void writeLog(const QString &timestamp, const QString &user, const QString &category, const QString &action, const QString &description);

private:
    explicit Logger(QObject *parent = nullptr);
    ~Logger();

    LogWorker *m_worker;
    QThread m_workerThread;
};

#endif // LOGGER_H
