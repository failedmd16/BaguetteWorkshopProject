#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include "src/DatabaseManager.h"
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQuickStyle::setStyle("Basic");

    qmlRegisterSingletonType<DatabaseManager>(
        "Database",  // Имя модуля
        1, 0,        // Версия
        "DatabaseManager",  // Имя синглтона в QML
        [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject* {
            Q_UNUSED(engine)
            Q_UNUSED(scriptEngine)
            return DatabaseManager::instance();
        });

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("project", "Main");

    app.setWindowIcon(QIcon("../../images/icon.ico"));

    return app.exec();
}
