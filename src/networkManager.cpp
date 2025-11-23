#include "networkManager.h"
#include <QCoreApplication>
#include <QTcpServer>
#include <QTcpSocket>
#include <QHostAddress>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QRegularExpression>
#include <qsqlquery.h>
#include "src/databaseManager.h"
#include "src/ollamaProvider.h"
#include "src/settingsManager.h"




NetworkManager::NetworkManager(DatabaseManager *dbManager, QObject *parent)
    : QObject(parent)
    , m_server(new QTcpServer(this))
    , m_dbManager(dbManager)
{
    connect(m_server, &QTcpServer::newConnection, this, &NetworkManager::handleNewConnection);
    connect(m_dbManager, &DatabaseManager::queueItemMarkedForProcessing,
            this, &NetworkManager::handleQueueItemMarked);

}


void NetworkManager::startServer() {
    QString host = SettingsManager::instance()->getValue("host", "http://0.0.0.0:54700").toString();

    // Extract port from the host string (remove "http://" and extract port after ":")
    QString cleanHost = host;
    if (cleanHost.startsWith("http://")) {
        cleanHost = cleanHost.mid(7); // Remove "http://"
    }

    int portColonIndex = cleanHost.lastIndexOf(':');
    if (portColonIndex != -1) {
        bool ok;
        int port = cleanHost.mid(portColonIndex + 1).toInt(&ok);
        if (ok) {
            if (m_server->listen(QHostAddress::Any, port)) {
                qDebug() << "📡 Server started on port:" << port;
                emit serverStarted();
            } else {
                qDebug() << "❌ Server failed to start:" << m_server->errorString();
                emit serverError(m_server->errorString());
            }
        } else {
            qDebug() << "❌ Invalid port in host setting:" << host;
            emit serverError("Invalid port in host setting");
        }
    } else {
        qDebug() << "❌ Invalid host format:" << host;
        emit serverError("Invalid host format");
    }
}

void NetworkManager::stopServer() {
    if (m_server->isListening()) {
        m_server->close();
        qDebug() << "📡 Server stopped";
        emit serverStopped();
    }
}

void NetworkManager::handleNewConnection() {
    QTcpSocket *clientSocket = m_server->nextPendingConnection();
    m_clients.append(clientSocket);

    connect(clientSocket, &QTcpSocket::readyRead, this, &NetworkManager::handleClientData);
    connect(clientSocket, &QTcpSocket::disconnected, this, &NetworkManager::handleClientDisconnected);

    qDebug() << "🔌 New client connected:" << clientSocket->peerAddress().toString();
}

void NetworkManager::handleClientData() {
    QTcpSocket *clientSocket = qobject_cast<QTcpSocket*>(sender());
    if (!clientSocket) return;

    QByteArray data = clientSocket->readAll();

    // Check if this is an HTTP request
    if (data.startsWith("POST") || data.startsWith("GET")) {
        // Parse HTTP request to extract JSON body
        QString fullRequest = QString::fromUtf8(data);
        QStringList parts = fullRequest.split("\r\n\r\n"); // Split headers from body

        if (parts.size() >= 2) {
            QString body = parts[1]; // Get the JSON body
            qDebug() << "📥 Received HTTP request body:" << body;
            processIncomingData(body.toUtf8());
        }
    } else {
        // Raw JSON (non-HTTP)
        qDebug() << "📥 Received raw data:" << data;
        processIncomingData(data);
    }

    // Send HTTP response back to client
    QString httpResponse = "HTTP/1.1 200 OK\r\n"
                           "Content-Type: text/plain\r\n"
                           "Connection: close\r\n"
                           "Content-Length: 2\r\n"
                           "\r\n"
                           "OK";
    clientSocket->write(httpResponse.toUtf8());
    clientSocket->flush();
    clientSocket->disconnectFromHost(); // Close connection after response
}

void NetworkManager::handleClientDisconnected() {
    QTcpSocket *clientSocket = qobject_cast<QTcpSocket*>(sender());
    if (clientSocket) {
        m_clients.removeAll(clientSocket);
        clientSocket->deleteLater();
        qDebug() << "🔌 Client disconnected:" << clientSocket->peerAddress().toString();
    }
}

void NetworkManager::processIncomingData(const QByteArray &data) {
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qDebug() << "❌ JSON parse error:" << parseError.errorString();
        return;
    }

    if (doc.isArray()) {
        // Handle array of entries (like from your Android app)
        QJsonArray entries = doc.array();
        for (const QJsonValue &value : entries) {
            if (value.isObject()) {
                QJsonObject obj = value.toObject();
                QString text = obj.value("text").toString();
                QString book = obj.value("book").toString();

                if (!text.isEmpty()) {
                    QVariantMap metadata;
                    metadata["source"] = "external_device";
                    if (!book.isEmpty()) {
                        metadata["book"] = book;
                    }
                    metadata["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

                    m_dbManager->addEntry(text, metadata);
                    qDebug() << "📥 Added external entry:" << text;
                }
            }
        }
    } else if (doc.isObject()) {
        // Handle single entry
        QJsonObject obj = doc.object();
        QString text = obj.value("text").toString();
        QString book = obj.value("book").toString();

        if (!text.isEmpty()) {
            QVariantMap metadata;
            metadata["source"] = "external_device";
            if (!book.isEmpty()) {
                metadata["book"] = book;
            }
            metadata["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);

            m_dbManager->addEntry(text, metadata);
            qDebug() << "📥 Added external entry:" << text;
        }
    }
}




// helper: extract all markdown bold words (**word**)
QStringList NetworkManager::extractBoldWords(const QString &text) {
    QStringList words;
    QRegularExpression re(R"(\*\*(.+?)\*\*)");
    QRegularExpressionMatchIterator it = re.globalMatch(text);
    while (it.hasNext()) {
        QRegularExpressionMatch match = it.next();
        QString word = match.captured(1).trimmed();
        if (!word.isEmpty())
            words << word;
    }
    return words;
}

// Helper to get default prompt file paths
QString NetworkManager::getDefaultPromptFilePath(const QString &type) {
    QString appDir = QCoreApplication::applicationDirPath();
    QString fileName = (type == "word") ? "wordPrompt.txt" : "sentencePrompt.txt";
    return QDir(appDir).absoluteFilePath(fileName);
}

// Add this helper function to your NetworkManager class
QString NetworkManager::readPromptFromFile(const QString &filePath, const QString &word, const QString &context) {
    QFile file(filePath);
    if (!file.exists()) {
        qWarning() << "Prompt file does not exist:" << filePath;
        return QString(); // Return empty string if file doesn't exist
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Cannot open prompt file:" << filePath;
        return QString(); // Return empty string if file can't be opened
    }

    QString prompt = file.readAll();
    file.close();

    // Replace {{word}} with the actual word
    prompt.replace("{{word}}", word);

    // Replace {{context}} with the context (sentence, etc.)
    prompt.replace("{{context}}", context);

    return prompt.trimmed();
}







void NetworkManager::handleQueueItemMarked(int id, const QString &itemType, const QString &formattedText) {
    qDebug() << "handleQueueItemMarked id=" << id << "type=" << itemType << "text=" << formattedText;

    if (itemType == "sentence") {
        processSentence(id, formattedText);
    } else if (itemType == "word") {
        processWord(id, formattedText);
    } else {
        qWarning() << "Unknown itemType in handleQueueItemMarked:" << itemType;
    }
}


// Utility: remove **bold** markdown except for the specific word
QString stripBoldExcept(const QString &sentence, const QString &targetWord) {
    QString result = sentence;

    // 1. Remove all bold markdown markers: **text**
    static QRegularExpression boldPattern(R"(\*\*(.*?)\*\*)");
    result.replace(boldPattern, "\\1");

    // 2. Re-apply bold formatting only to the target word (whole word match)
    // Escape word for regex
    QString escaped = QRegularExpression::escape(targetWord);

    // Match whole words: \bword\b, but for Unicode Qt recommends using lookarounds
    QRegularExpression wordPattern(QString("(?<!\\w)(%1)(?!\\w)").arg(escaped));

    // Replace with bold version
    result.replace(wordPattern, "**\\1**");

    return result;
}


QJsonObject NetworkManager::parseJson(const QString &jsonString) {
    QString cleaned = jsonString.trimmed();

    // Remove markdown code block markers if present
    if (cleaned.startsWith("```json", Qt::CaseInsensitive)) {
        cleaned = cleaned.mid(7).trimmed(); // Remove "```json"
    }
    if (cleaned.endsWith("```")) {
        int lastBacktick = cleaned.lastIndexOf("```");
        if (lastBacktick > 0) {
            cleaned = cleaned.left(lastBacktick).trimmed(); // Remove trailing "```"
        }
    }

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(cleaned.toUtf8(), &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "JSON parsing error:" << parseError.errorString();
        qWarning() << "Original string:" << jsonString;

        // Return error JSON object
        QJsonObject errorObj;
        errorObj["meta"] = QJsonObject{
            {"is_valid", false},
            {"Error", parseError.errorString()}
        };
        return errorObj;
    }

    if (doc.isObject()) {
        return doc.object();
    } else {
        qWarning() << "JSON is not an object, returning error structure";
        QJsonObject errorObj;
        errorObj["meta"] = QJsonObject{
            {"is_valid", false},
            {"Error", "JSON is not an object"}
        };
        return errorObj;
    }
}



void NetworkManager::processSentence(int id, const QString &formattedText) {
    QString sentencePromptFile = SettingsManager::instance()->getValue("sentence_prompt_file", getDefaultPromptFilePath("sentence")).toString();
    QString prompt = readPromptFromFile(sentencePromptFile, "", formattedText);
    if (prompt.isEmpty()) {
        prompt = QString("Analyze this sentence and produce a JSON object with fields: explanation (string), important_words (array of strings). Sentence: \"%1\"").arg(formattedText);
    }

    // send prompt
    OllamaProvider *provider = new OllamaProvider(this);
    connect(provider, &OllamaProvider::responseReceived, this, [this, provider, id](const QString &response) {
        provider->deleteLater();
        qDebug() << "Sentence AI response:" << response;
        // store raw ai response into sentences.ai_response and mark processed=2
        QJsonObject parsedJson = parseJson(response);
        // Convert back to string for database storage
        QJsonDocument doc(parsedJson);
        QString finalResponse = doc.toJson(QJsonDocument::Compact);
        m_dbManager->updateSentenceWithAIAnalysis(id, finalResponse);

        // fallback: fall back to regex: extract **bold** text or fallback to your extractBoldWords call
        QString sentenceText = m_dbManager->getSentencesProfile(id).value("text").toString();
        QStringList boldWords = extractBoldWords(sentenceText);
        for (const QString &w : boldWords) {
            // pass clearText Except
            QString context = stripBoldExcept(sentenceText, w);
            qDebug() << "bold word: " << w << " context: " << context;


            int newWordId = m_dbManager->insertWordProfile(w, context.isEmpty() ? w : context );
            if (newWordId > 0) processWord(newWordId, context);
        }
    });
    provider->sendPrompt(prompt, /*model*/ SettingsManager::instance()->getValue("model").toString());
}





void NetworkManager::processWord(int id, const QString &context) {
    QString word = m_dbManager->getWordProfile(id).value("word").toString();

    QString wordPromptFile = SettingsManager::instance()->getValue("word_prompt_file", getDefaultPromptFilePath("word")).toString();
    QString prompt = readPromptFromFile(wordPromptFile, word, context);
    if (prompt.isEmpty()) {
        prompt = QString(R"(
Return ONLY valid JSON object (no commentary) with keys:
{
  "type": "noun|verb|adjective|adverb|phrase",
  "definition": "short definition",
  "synonyms": ["s1","s2"],
  "antonyms": ["a1","a2"],
  "example_sentences": ["ex1","ex2"]
}
Word: "%1"
Context: "%2"
)").arg(word, context);
    }

    OllamaProvider *provider = new OllamaProvider(this);
    connect(provider, &OllamaProvider::responseReceived, this, [this, provider, id, word](const QString &response) {
        provider->deleteLater();
        qDebug() << "Word AI response for" << word << ":" << response;

        // Parse the JSON response (this handles markdown removal and error handling)
        QJsonObject parsedJson = parseJson(response);

        // Convert back to string for database storage
        QJsonDocument doc(parsedJson);
        QString finalResponse = doc.toJson(QJsonDocument::Compact);

        // Check if parsing was successful (is_valid will be false if there was an error)
        QJsonValue metaValue = parsedJson.value("meta");
        if (!metaValue.isObject() || !parsedJson.value("meta").toObject().value("is_valid").toBool(true)) {
            // Parsing failed, use fallback
            m_dbManager->updateWordProfileWithAIFallback(id, finalResponse);
            return;
        }

        // Extract type from the parsed JSON
        QString type;

        // Try to get type from meta.part_of_speech first (based on your expected JSON)
        QJsonValue metaObj = parsedJson.value("meta");
        if (metaObj.isObject()) {
            type = metaObj.toObject().value("part_of_speech").toString();
        }

        // If not found in meta, try the root level (for your fallback prompt format)
        if (type.isEmpty()) {
            type = parsedJson.value("type").toString();
        }

        // If still empty, use a default
        if (type.isEmpty()) {
            type = "unknown";
        }

        // Update the database with both the response and the type
        m_dbManager->updateWordProfileWithAIFallback(id, finalResponse); // This sets processed=2 and stores the response
        m_dbManager->updateWordProfileType(id, type); // This updates just the type field
    });
    provider->sendPrompt(prompt, SettingsManager::instance()->getValue("model").toString());
}





// void NetworkManager::handleQueueItemMarked(int id, const QString &itemType, const QString &formattedText) {
//     QString provider = SettingsManager::instance()->getValue("provider", "Ollama").toString();
//     QString model = SettingsManager::instance()->getValue("model", "llama3.1-16k:latest").toString();
//     qDebug() << "🚀 Processing sentence ID:" << id << " type: " << itemType  << " text:" << formattedText << "with provider:" << provider;
//     QString sentencePromptFile = SettingsManager::instance()->getValue("sentence_prompt_file", getDefaultPromptFilePath("sentence")).toString();
//     QString sentencePrompt = readPromptFromFile(sentencePromptFile, "", formattedText);

//     if (sentencePrompt.isEmpty()) {
//         sentencePrompt = QString("Analyze this sentence and explain the vocabulary: '%1'").arg(formattedText);
//     }

//     // ignore in case of being one word?
//     // this seems to not care about what provider user is using?
//     OllamaProvider *mainProvider = new OllamaProvider(this);
//     connect(mainProvider, &OllamaProvider::responseReceived, [this, id](const QString &response) {
//         qDebug() << "💬 Sentence analysis response:" << response;
//         m_dbManager->updateSentenceWithAIAnalysis(id, response);
//     });
//     mainProvider->sendPrompt(sentencePrompt, model);


//     QStringList boldWords = extractBoldWords(formattedText);
//     for (const QString &word : boldWords) {
//         QString wordPromptFile = SettingsManager::instance()->getValue("word_prompt_file", getDefaultPromptFilePath("word")).toString();
//         QString wordPrompt = readPromptFromFile(wordPromptFile, word, formattedText);
//         if (wordPrompt.isEmpty()) {
//             wordPrompt = QString("Explain the meaning, usage, and example sentence for the word: '%1' which came from the following sentence: '%2'").arg(word, formattedText);
//         }
//         qDebug() << "🔍 Word prompt:" << wordPrompt;

//         OllamaProvider *wordProvider = new OllamaProvider(this);
//         connect(wordProvider, &OllamaProvider::responseReceived, [this, formattedText, word](const QString &response) {
//             qDebug() << "📘 Word JSON response for" << word << ":" << response;

//             QJsonParseError err;
//             QJsonDocument doc = QJsonDocument::fromJson(response.toUtf8(), &err);

//             if (err.error != QJsonParseError::NoError || !doc.isObject()) {
//                 qWarning() << "❌ Invalid JSON for word:" << word << "error:" << err.errorString();
//                 return;
//             }

//             QJsonObject obj = doc.object();

//             QString type      = obj.value("type").toString();
//             QString definition = obj.value("definition").toString();
//             QString synonyms   = QJsonDocument(obj.value("synonyms").toArray()).toJson(QJsonDocument::Compact);
//             QString antonyms   = QJsonDocument(obj.value("antonyms").toArray()).toJson(QJsonDocument::Compact);
//             QString examples   = QJsonDocument(obj.value("example_sentences").toArray()).toJson(QJsonDocument::Compact);

//             m_dbManager->insertWordProfile(
//                 word,
//                 formattedText,
//                 type,
//                 definition,
//                 examples,
//                 synonyms,
//                 antonyms
//             );
//         });

//         wordProvider->sendPrompt(wordPrompt, model);
//     }
// }


// regenerate button need to be worked on later!
// void NetworkManager::regenerateContent(int id, const QString &table) {
//     QString provider = SettingsManager::instance()->getValue("provider", "Ollama").toString();
//     QString model = SettingsManager::instance()->getValue("model", "llama3.1-16k:latest").toString();


//     qDebug() << "🔄 Regenerating" << table << "ID:" << id << "with provider:" << provider;

//     if (provider.compare("Ollama", Qt::CaseInsensitive) == 0) {
//         emit contentRegenerationStarted(id, table);

//         if (table == "sentence") {
//             QString text = m_dbManager->getSentencesProfile(id).value("text").toString();
//             QStringList boldWords = extractBoldWords(text);
//             qDebug() << "🧠 Extracted bold words:" << boldWords;

//             QString cleanText = text;
//             for (const QString &word : boldWords) {
//                 cleanText.replace("**" + word + "**", word);
//             }

//             // Get sentence prompt file path from settings, fallback to default
//             QString sentencePromptFile = SettingsManager::instance()->getValue("sentence_prompt_file", getDefaultPromptFilePath("sentence")).toString();
//             QString sentencePrompt = readPromptFromFile(sentencePromptFile, "", cleanText);

//             if (sentencePrompt.isEmpty()) {
//                 sentencePrompt = QString("Analyze this sentence and explain the vocabulary: '%1'").arg(cleanText);
//             }

//             qDebug() << "🎯 Ollama sentence prompt:" << sentencePrompt;

//             OllamaProvider *mainProvider = new OllamaProvider(this);
//             connect(mainProvider, &OllamaProvider::responseReceived, [this, id](const QString &response) {
//                 qDebug() << "💬 Sentence analysis response:" << response;
//                 m_dbManager->updateSentenceWithAIAnalysis(id, response);
//                 emit contentRegenerated(id, "sentence");
//             });
//             mainProvider->sendPrompt(sentencePrompt, model);

//             for (const QString &word : boldWords) {
//                 QString wordPromptFile = SettingsManager::instance()->getValue("word_prompt_file", getDefaultPromptFilePath("word")).toString();
//                 QString wordPrompt = readPromptFromFile(wordPromptFile, word, cleanText);

//                 if (wordPrompt.isEmpty()) {
//                     wordPrompt = QString("Explain the meaning, usage, and example sentence for the word: '%1'").arg(word);
//                 }

//                 qDebug() << "🔍 Word prompt:" << wordPrompt;

//                 OllamaProvider *wordProvider = new OllamaProvider(this);
//                 connect(wordProvider, &OllamaProvider::responseReceived, [this, word, text](const QString &response) {
//                     qDebug() << "📘 Word response for" << word << ":" << response;
//                     m_dbManager->createWordProfile(word, text, response);
//                 });
//                 wordProvider->sendPrompt(wordPrompt, model);
//             }
//         } else if (table == "word") {
//             QString text = m_dbManager->getWordProfile(id).value("word").toString();
//             QString context = m_dbManager->getWordProfile(id).value("context").toString();

//             QString wordPromptFile = SettingsManager::instance()->getValue("word_prompt_file", getDefaultPromptFilePath("word")).toString();
//             QString wordPrompt = readPromptFromFile(wordPromptFile, text, context);

//             if (wordPrompt.isEmpty()) {
//                 wordPrompt = QString("Provide detailed information about the word '%1': definition, usage, examples, and memory tips.").arg(text);
//             }

//             qDebug() << "🔍 Word regeneration prompt:" << wordPrompt;

//             OllamaProvider *wordProvider = new OllamaProvider(this);
//             connect(wordProvider, &OllamaProvider::responseReceived, [this, id](const QString &response) {
//                 qDebug() << "📘 Updated word response:" << response;
//                 m_dbManager->updateWordProfile(id, response);
//                 emit contentRegenerated(id, "word");
//             });
//             wordProvider->sendPrompt(wordPrompt, model);
//         }
//     }
// }


void NetworkManager::regenerateContent(int id, const QString &table) {
    QString provider = SettingsManager::instance()->getValue("provider", "Ollama").toString();
    QString model = SettingsManager::instance()->getValue("model", "llama3.1-16k:latest").toString();

    qDebug() << "🔄 Regenerating" << table << "ID:" << id << "with provider:" << provider;

    if (provider.compare("Ollama", Qt::CaseInsensitive) == 0) {
        emit contentRegenerationStarted(id, table);

        if (table == "sentence") {
            QString text = m_dbManager->getSentencesProfile(id).value("text").toString();
            QStringList boldWords = extractBoldWords(text);
            qDebug() << "🧠 Extracted bold words:" << boldWords;

            QString cleanText = text;
            for (const QString &word : boldWords) {
                cleanText.replace("**" + word + "**", word);
            }

            // Get sentence prompt file path from settings, fallback to default
            QString sentencePromptFile = SettingsManager::instance()->getValue("sentence_prompt_file", getDefaultPromptFilePath("sentence")).toString();
            QString sentencePrompt = readPromptFromFile(sentencePromptFile, "", cleanText);

            if (sentencePrompt.isEmpty()) {
                sentencePrompt = QString("Analyze this sentence and explain the vocabulary: '%1'").arg(cleanText);
            }

            qDebug() << "🎯 Ollama sentence prompt:" << sentencePrompt;

            OllamaProvider *mainProvider = new OllamaProvider(this);
            connect(mainProvider, &OllamaProvider::responseReceived, [this, id](const QString &response) {
                qDebug() << "💬 Sentence analysis response:" << response;

                // Parse JSON and handle errors
                QJsonObject parsedJson = parseJson(response);
                QJsonDocument doc(parsedJson);
                QString finalResponse = doc.toJson(QJsonDocument::Compact);

                m_dbManager->updateSentenceWithAIAnalysis(id, finalResponse);
                emit contentRegenerated(id, "sentence");
            });
            mainProvider->sendPrompt(sentencePrompt, model);

            for (const QString &word : boldWords) {
                QString wordPromptFile = SettingsManager::instance()->getValue("word_prompt_file", getDefaultPromptFilePath("word")).toString();
                QString wordPrompt = readPromptFromFile(wordPromptFile, word, cleanText);

                if (wordPrompt.isEmpty()) {
                    wordPrompt = QString("Explain the meaning, usage, and example sentence for the word: '%1'").arg(word);
                }

                qDebug() << "🔍 Word prompt:" << wordPrompt;

                OllamaProvider *wordProvider = new OllamaProvider(this);
                connect(wordProvider, &OllamaProvider::responseReceived, [this, word, text](const QString &response) {
                    qDebug() << "📘 Word response for" << word << ":" << response;

                    // Parse JSON and handle errors
                    QJsonObject parsedJson = parseJson(response);
                    QJsonDocument doc(parsedJson);
                    QString finalResponse = doc.toJson(QJsonDocument::Compact);

                    m_dbManager->createWordProfile(word, text, finalResponse);
                });
                wordProvider->sendPrompt(wordPrompt, model);
            }
        } else if (table == "word") {
            QString text = m_dbManager->getWordProfile(id).value("word").toString();
            QString context = m_dbManager->getWordProfile(id).value("context").toString();

            QString wordPromptFile = SettingsManager::instance()->getValue("word_prompt_file", getDefaultPromptFilePath("word")).toString();
            QString wordPrompt = readPromptFromFile(wordPromptFile, text, context);

            if (wordPrompt.isEmpty()) {
                wordPrompt = QString("Provide detailed information about the word '%1': definition, usage, examples, and memory tips.").arg(text);
            }

            qDebug() << "🔍 Word regeneration prompt:" << wordPrompt;

            OllamaProvider *wordProvider = new OllamaProvider(this);
            connect(wordProvider, &OllamaProvider::responseReceived, [this, id](const QString &response) {
                qDebug() << "📘 Updated word response:" << response;

                // Parse JSON and handle errors
                QJsonObject parsedJson = parseJson(response);

                // Extract type for database update
                QString type;
                QJsonValue metaObj = parsedJson.value("meta");
                if (metaObj.isObject()) {
                    type = metaObj.toObject().value("part_of_speech").toString();
                }
                if (type.isEmpty()) {
                    type = parsedJson.value("type").toString();
                }
                if (type.isEmpty()) {
                    type = "unknown";
                }

                // Convert to string for database storage
                QJsonDocument doc(parsedJson);
                QString finalResponse = doc.toJson(QJsonDocument::Compact);

                // Update both the response and type
                m_dbManager->updateWordProfileWithAIFallback(id, finalResponse);
                m_dbManager->updateWordProfileType(id, type);

                emit contentRegenerated(id, "word");
            });
            wordProvider->sendPrompt(wordPrompt, model);
        }
    }
}
