#include "logger.h"

/*!
 * \brief Деструктор LogWorker.
 *
 * Закрывает соединение с базой данных, если оно было открыто
 * под уникальным именем соединения.
 */
LogWorker::~LogWorker()
{
    if (QSqlDatabase::contains(m_connectionName))
    {
        QSqlDatabase::database(m_connectionName).close();
    }
}

/*!
 * \brief Настраивает и открывает соединение с БД.
 *
 * Использует драйвер QPSQL.
 */
void LogWorker::connectToDatabase()
{
    if (QSqlDatabase::contains(m_connectionName))
    {
        return;
    }

    QSqlDatabase db = QSqlDatabase::addDatabase("QPSQL", m_connectionName);
    db.setDatabaseName("bws_db");
    db.setHostName("72.56.238.251");
    db.setPort(5000);
    db.setUserName("bws_user");
    db.setPassword("Mx95dLtM5xtbfJ3aAyMzF9ZOuUxrWIZt");
    db.setConnectOptions("sslmode=require;connect_timeout=10");

    if (!db.open())
    {
        qDebug() << "AsyncLogger: Connection failed:" << db.lastError().text();
    }
}

/*!
 * \brief Получает или создает подключение к БД.
 * \return Инициализированный объект QSqlDatabase.
 */
QSqlDatabase LogWorker::getDatabase()
{
    if (!QSqlDatabase::contains(m_connectionName))
    {
        connectToDatabase();
    }
    return QSqlDatabase::database(m_connectionName);
}

/*!
 * \brief Реализация слота записи лога.
 * \sa Logger::writeLog
 */
void LogWorker::processLog(const QString &timestamp, const QString &user, const QString &category, const QString &action, const QString &description)
{
    QSqlDatabase db = getDatabase();

    if (!db.isOpen()) {
        if (!db.open()) {
            qDebug() << "AsyncLogger: DB lost and failed to reopen.";
            return;
        }
    }

    QSqlQuery query(db);
    query.prepare("INSERT INTO event_logs (username, category, action, details) "
                  "VALUES (:user, :cat, :act, :details)");

    if (user.isEmpty())
        query.bindValue(":user", "System");
    else
        query.bindValue(":user", user);

    query.bindValue(":cat", category);
    query.bindValue(":act", action);
    query.bindValue(":details", description);

    if (!query.exec())
        qDebug() << "AsyncLogger: Insert error:" << query.lastError().text();
}
/*!
 * \brief Возвращает статический экземпляр Logger.
 */
Logger& Logger::instance()
{
    static Logger _instance;
    return _instance;
}

/*!
 * \brief Инициализирует Logger и запускает рабочий поток.
 */
Logger::Logger(QObject *parent) : QObject(parent)
{
    m_worker = new LogWorker();

    m_worker->moveToThread(&m_workerThread);

    connect(this, &Logger::writeLog, m_worker, &LogWorker::processLog);
    connect(&m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);

    m_workerThread.start();
}

/*!
 * \brief Завершает работу потока и уничтожает объект.
 */
Logger::~Logger()
{
    m_workerThread.quit();
    m_workerThread.wait();
}

/*!
 * \brief Публичный метод для добавления записи в лог.
 *
 * Генерирует текущую временную метку и передает данные
 * в асинхронный поток.
 */
void Logger::log(const QString &user, const QString &category, const QString &action, const QString &description)
{
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");

    emit writeLog(timestamp, user, category, action, description);
}
