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

class DatabaseManager;

class NetworkManager : public QObject {
    Q_OBJECT

public:
    explicit NetworkManager(DatabaseManager *dbManager, QObject *parent = nullptr);
    void handleQueueItemMarked(int id, const QString &itemType, const QString &formattedText);
    Q_INVOKABLE void regenerateContent(int id, const QString &table);

    void startServer();
    void stopServer();

signals:
    void contentRegenerated(int id, const QString &type);
    void contentRegenerationStarted(int id, const QString &type);
    void serverStarted();
    void serverStopped();
    void serverError(const QString &error);
    void queueItemMarkedForProcessing(int id, const QString &type, const QString &formattedText);
    void queueChanged();



private slots:
    void handleNewConnection();
    void handleClientData();
    void handleClientDisconnected();


private:
    QNetworkAccessManager *m_nam;
    DatabaseManager *m_dbManager;
    QStringList extractBoldWords(const QString &text);
    QString readPromptFromFile(const QString &filePath, const QString &word, const QString &context);
    QString getDefaultPromptFilePath(const QString &type);

    void markQueueItemToProcess(int id, const QString &formattedText, const QString &itemType);
    void processSentence(int id, const QString &formattedText);
    void processWord(int id, const QString &context);
    void processSentenceFlow(int id, const QString &formattedText);
    void processWordFromSentence(const QString &word, const QString &context);
    void processSingleWordFlow(int id, const QString &word, const QString &context);


    QTcpServer *m_server;
    QList<QTcpSocket*> m_clients;

    void processIncomingData(const QByteArray &data);

};

#endif // NETWORKMANAGER_H
