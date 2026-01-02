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

// --- КЛАСС РАБОЧЕГО (Выполняет запись в отдельном потоке) ---
class LogWorker : public QObject {
    Q_OBJECT
public:
    explicit LogWorker(QObject *parent = nullptr) : QObject(parent) {}
    ~LogWorker();

public slots:
    // Этот слот будет выполняться в фоновом потоке
    void processLog(const QString &timestamp, const QString &user, const QString &category, const QString &action, const QString &description);

private:
    void connectToDatabase();
    QSqlDatabase getDatabase();
    const QString m_connectionName = "AsyncLoggerConnection"; // Уникальное имя для потока
};

// --- ОСНОВНОЙ КЛАСС (Интерфейс для C++ и QML) ---
class Logger : public QObject
{
    Q_OBJECT
public:
    static Logger& instance();

    // Метод, вызываемый из C++ и QML
    Q_INVOKABLE void log(const QString &user, const QString &category, const QString &action, const QString &description);

signals:
    // Сигнал передает данные в Worker
    void writeLog(const QString &timestamp, const QString &user, const QString &category, const QString &action, const QString &description);

private:
    explicit Logger(QObject *parent = nullptr);
    ~Logger();

    LogWorker *m_worker;
    QThread m_workerThread;
};

#endif // LOGGER_H
