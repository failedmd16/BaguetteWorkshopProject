#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "src/DatabaseManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<DatabaseManager>("databasemanager", 1, 0, "DatabaseManager"); // Связывание QML и cpp

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("project", "Main");

    return app.exec();
}
