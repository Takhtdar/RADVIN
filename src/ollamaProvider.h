#ifndef OLLAMAPROVIDER_H
#define OLLAMAPROVIDER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>

class OllamaProvider : public QObject
{
    Q_OBJECT

public:
    explicit OllamaProvider(QObject *parent = nullptr);

    void sendPrompt(const QString &prompt, const QString &model);

signals:
    void responseReceived(const QString &response);
    void errorOccurred(const QString &errorMessage);

private slots:
    void onNetworkReplyFinished(QNetworkReply *reply);

private:
    QNetworkAccessManager *m_networkManager;
};

#endif // OLLAMAPROVIDER_H
