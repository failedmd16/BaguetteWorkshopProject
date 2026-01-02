#include "logger.h"

// ---------------------------------------------------------
// Реализация LogWorker (Фоновый поток)
// ---------------------------------------------------------

LogWorker::~LogWorker() {
    if (QSqlDatabase::contains(m_connectionName)) {
        QSqlDatabase::database(m_connectionName).close();
    }
}

void LogWorker::connectToDatabase() {
    // Настраиваем соединение только один раз внутри потока
    if (QSqlDatabase::contains(m_connectionName)) return;

    QSqlDatabase db = QSqlDatabase::addDatabase("QPSQL", m_connectionName);
    db.setDatabaseName("failedmd16");
    db.setHostName("pg4.sweb.ru");
    db.setPort(5433);
    db.setUserName("failedmd16");
    db.setPassword("Bagetworkshop123");
    db.setConnectOptions("requiressl=0;connect_timeout=10");

    if (!db.open()) {
        qDebug() << "AsyncLogger: Connection failed:" << db.lastError().text();
    } else {
        qDebug() << "AsyncLogger: Connected in background thread.";
    }
}

QSqlDatabase LogWorker::getDatabase() {
    if (!QSqlDatabase::contains(m_connectionName)) {
        connectToDatabase();
    }
    return QSqlDatabase::database(m_connectionName);
}

void LogWorker::processLog(const QString &timestamp, const QString &user, const QString &category, const QString &action, const QString &description) {
    QSqlDatabase db = getDatabase();

    // Если соединение отвалилось, пробуем переподключиться
    if (!db.isOpen()) {
        if (!db.open()) {
            qDebug() << "AsyncLogger: DB lost and failed to reopen.";
            return;
        }
    }

    QSqlQuery query(db);
    query.prepare("INSERT INTO event_logs (timestamp, user_login, category, action, description) "
                  "VALUES (:ts, :user, :cat, :act, :desc)");

    // Приведение типов для PostgreSQL
    query.bindValue(":ts", QVariant(timestamp));
    query.bindValue(":user", user.isEmpty() ? "System" : user);
    query.bindValue(":cat", category);
    query.bindValue(":act", action);
    query.bindValue(":desc", description);

    if (!query.exec()) {
        qDebug() << "AsyncLogger: Insert error:" << query.lastError().text();
    }
}

// ---------------------------------------------------------
// Реализация Logger (Основной поток)
// ---------------------------------------------------------

Logger& Logger::instance() {
    static Logger _instance;
    return _instance;
}

Logger::Logger(QObject *parent) : QObject(parent) {
    m_worker = new LogWorker();

    // Перемещаем воркера в отдельный поток
    m_worker->moveToThread(&m_workerThread);

    // Соединяем сигнал интерфейса со слотом воркера
    // Qt::QueuedConnection гарантирует, что слот выполнится в потоке воркера
    connect(this, &Logger::writeLog, m_worker, &LogWorker::processLog);

    // Удаляем воркера, когда поток завершится
    connect(&m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);

    // Запускаем поток
    m_workerThread.start();
}

Logger::~Logger() {
    m_workerThread.quit();
    m_workerThread.wait();
}

void Logger::log(const QString &user, const QString &category, const QString &action, const QString &description) {
    // Формируем время здесь, в главном потоке, чтобы оно было точным на момент вызова
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");

    // Эмитим сигнал. Благодаря QueuedConnection управление вернется мгновенно,
    // а запись произойдет в фоне.
    emit writeLog(timestamp, user, category, action, description);
}
