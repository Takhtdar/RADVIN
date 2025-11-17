#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDateTime>
#include "src/clipboardListener.h"
#include "src/databaseManager.h"
#include "src/settingsManager.h"
#include "src/networkManager.h"
#include <QOperatingSystemVersion>
#include <QUrl>
#include <QSharedMemory>
#include <QSystemSemaphore>
#include <QQuickStyle>
#include <QPalette>


int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    SettingsManager::instance()->setValue("clipboard_enabled", false);

    QPalette palette;
    palette.setColor(QPalette::Window, Qt::white);
    palette.setColor(QPalette::WindowText, Qt::black);
    palette.setColor(QPalette::Base, Qt::white);
    palette.setColor(QPalette::Text, Qt::black);
    app.setPalette(palette);

    QString deviceType = "Desktop"; // Default
    QString platformQMLPath;

    #if defined(Q_OS_ANDROID)
        qDebug() << "📱 Detected Android platform";
        platformQMLPath = "qrc:///UI/Shared/Main.qml"; // ✅ Full path to Android QML
        deviceType = "Phone";
    #elif defined(Q_OS_IOS)
        qDebug() << "📱 Detected iOS platform";
        platformQMLPath = "qrc:///UI/iOS/Main.qml"; // ✅ Full path to iOS QML
    #else
        qDebug() << "🖥️ Detected Desktop platform";
        platformQMLPath = "qrc:///UI/Shared/Main.qml"; // ✅ Full path to Desktop QML

        qputenv("QT_QUICK_CONTROLS_STYLE", "Basic"); // No theme

        // ✅ Singleton: Allow only one instance
        QSharedMemory sharedMem("RadvinApp_Singleton_Mutex");
        if (!sharedMem.create(1)) {
            qWarning() << "⚠️ Another instance of RADVIN is already running!";
            return 0;
        }

    #endif




    ClipboardListener clipboardListener;
    DatabaseManager dbManager("RADVIN.db");
    NetworkManager networkManager(&dbManager);
    QObject::connect(
        &dbManager,
        &DatabaseManager::queueItemMarkedForProcessing,
        &networkManager,
        &NetworkManager::handleQueueItemMarked
        );
 app.setQuitOnLastWindowClosed(false);




    SettingsManager::instance()->setValue("listen_external_queue", false);


    bool listenEnabled = SettingsManager::instance()->getValue("listen_external_queue", false).toBool();
    if (listenEnabled) {
        networkManager.startServer();
    }
    QObject::connect(SettingsManager::instance(), &SettingsManager::settingChanged,
     [&networkManager](const QString &key) {
         if (key == "listen_external_queue") {
             bool enabled = SettingsManager::instance()->getValue("listen_external_queue", false).toBool();
             if (enabled) {
                 networkManager.startServer();
             } else {
                 networkManager.stopServer();
             }
         } else if (key == "host") {
             // If host changes while server is running, restart it
             bool listenEnabled = SettingsManager::instance()->getValue("listen_external_queue", false).toBool();
             if (listenEnabled) {
                 networkManager.stopServer();
                 networkManager.startServer();
             }
         }
     });



    QObject::connect(SettingsManager::instance(), &SettingsManager::settingChanged,
        [&](const QString &key) {
            if (key == "clipboard_enabled") {
             bool enabled = SettingsManager::instance()->getValue("clipboard_enabled", false).toBool();
             clipboardListener.setEnabled(enabled);
             qDebug() << "📎 Setting changed: clipboard_enabled =" << enabled;
        }
    });

    QObject::connect(&clipboardListener, &ClipboardListener::textCopied,
     [&](const QString &text) {
         bool isClipboardEnabled = SettingsManager::instance()
                                       ->getValue("clipboard_enabled", false)
                                       .toBool();

         if (!isClipboardEnabled) {
             qDebug() << "🔒 Clipboard monitoring is OFF — ignoring copied text";
             return; // ✅ Early exit if disabled
         }

         qDebug() << "📎 Clipboard monitoring is ON — saving copied text";
         QVariantMap metadata;
         metadata["source"] = "clipboard";
         metadata["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
         dbManager.addEntry(text, metadata);
         emit clipboardListener.clipboardSaved();
    });

    if (SettingsManager::instance()->getValue("clipboard_enabled", false).toBool()) {
        qDebug() << "Toggle ON — starting clipboard listener";
        clipboardListener.start();
    } else {
        qDebug() << "🔒 Clipboard listener NOT started";
        if (!SettingsManager::instance()->getValue("clipboard_enabled", false).toBool())
            qDebug() << "  → Toggle is OFF";
    }

    QQmlApplicationEngine engine;

    // 🌐 Expose managers to QML
    engine.rootContext()->setContextProperty("deviceType", deviceType);
    engine.rootContext()->setContextProperty("clipboardListener", &clipboardListener);
    engine.rootContext()->setContextProperty("dbManager", &dbManager);
    engine.rootContext()->setContextProperty("networkManager", &networkManager);
    engine.rootContext()->setContextProperty("settings", SettingsManager::instance());

    qDebug() << "🎨 Loading QML file:" << platformQMLPath;
    engine.load((platformQMLPath)); // ✅ Use load() with full path

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "❌ Failed to load platform-specific QML:" << platformQMLPath;
        return -1;
    }


    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    return app.exec();
}
