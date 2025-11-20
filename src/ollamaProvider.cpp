#include "ollamaProvider.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include "src/settingsManager.h"

OllamaProvider::OllamaProvider(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &OllamaProvider::onNetworkReplyFinished);
}

void OllamaProvider::sendPrompt(const QString &prompt, const QString &model)
{
    QJsonObject jsonRequest;
    jsonRequest["model"] = model;

    QJsonArray messages;
    QJsonObject message;
    message["role"] = "user";
    message["content"] = prompt;
    messages.append(message);
    jsonRequest["messages"] = messages;
    jsonRequest["temperature"] = 0;
    jsonRequest["stream"] = false;

    QJsonDocument doc(jsonRequest);
    QByteArray requestData = doc.toJson();

    QNetworkRequest request;
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setUrl(QUrl(SettingsManager::instance()->getValue("provider_address", "http://127.0.0.1:11434/api/chat").toString()));

    m_networkManager->post(request, requestData);
}

void OllamaProvider::onNetworkReplyFinished(QNetworkReply *reply)
{
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray response = reply->readAll();
        QJsonParseError parseError;
        QJsonDocument responseDoc = QJsonDocument::fromJson(response, &parseError);

        if (parseError.error == QJsonParseError::NoError) {
            QJsonObject responseObj = responseDoc.object();
            QJsonValue messageValue = responseObj.value("message");

            if (messageValue.isObject()) {
                QString content = messageValue.toObject().value("content").toString();
                emit responseReceived(content);
            } else {
                emit responseReceived("No content in response");
            }
        } else {
            emit errorOccurred("JSON parse error: " + parseError.errorString());
        }
    } else {
        emit errorOccurred(reply->errorString());
    }

    reply->deleteLater();
}
