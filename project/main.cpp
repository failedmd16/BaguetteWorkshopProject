#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include "src/DatabaseManager.h"
#include <QQuickStyle>

/*!
 * \brief Главная точка входа в приложение.
 *
 * Выполняет инициализацию графического приложения, устанавливает стиль интерфейса,
 * регистрирует C++ синглтоны (DatabaseManager, Logger) для доступа из QML
 * и загружает основной QML модуль.
 */

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQuickStyle::setStyle("Basic");

    qmlRegisterSingletonType<DatabaseManager>("Database", 1, 0,"DatabaseManager", [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject* {
        Q_UNUSED(engine)
        Q_UNUSED(scriptEngine)
        return DatabaseManager::instance();
    });

    Logger::instance();
    qmlRegisterSingletonInstance("AppLogger", 1, 0, "Logger", &Logger::instance());

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("project", "Main");

    app.setWindowIcon(QIcon("images/icon.ico"));

    return app.exec();
}
