#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QVariantList>
#include <QTcpServer>
#include <QTcpSocket>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

class DatabaseManager; // Forward declaration

class NetworkManager : public QObject {
    Q_OBJECT

public:
    explicit NetworkManager(DatabaseManager *dbManager, QObject *parent = nullptr);
    void handleSentenceMarked(int id, const QString &formattedText);
    Q_INVOKABLE void regenerateContent(int id, const QString &table);

    void startServer();
    void stopServer();

signals:
    void contentRegenerated(int id, const QString &type);
    void contentRegenerationStarted(int id, const QString &type);
    void serverStarted();
    void serverStopped();
    void serverError(const QString &error);


private slots:
    void handleNewConnection();
    void handleClientData();
    void handleClientDisconnected();


private:
    QNetworkAccessManager *m_nam;
    DatabaseManager *m_dbManager; // ✅ Pointer to existing DB manager
    QStringList extractBoldWords(const QString &text);
    QString readPromptFromFile(const QString &filePath, const QString &word, const QString &context);
    QString getDefaultPromptFilePath(const QString &type); // Add this line

    QTcpServer *m_server;
    QList<QTcpSocket*> m_clients;

    void processIncomingData(const QByteArray &data);

};

#endif // NETWORKMANAGER_H
