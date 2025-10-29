#include "databaseManager.h"
#include <QDebug>
#include <QSqlQuery>
#include <QSqlError>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QSqlRecord>

DatabaseManager::DatabaseManager(const QString &path, QObject *parent)
    : QObject(parent)
{
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(path);

    if (!m_db.open()) {
        qCritical() << "❌ Failed to open database:" << m_db.lastError().text();
        return;
    }

    if (!createTables()) {
        qCritical() << "❌ Failed to create tables";
    }
}

bool DatabaseManager::createTables() {
    QSqlQuery query(m_db);
    bool success = query.exec(R"(
    CREATE TABLE IF NOT EXISTS sentences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        metadata TEXT, -- JSON string
        processed INTEGER DEFAULT 0,
        ai_response TEXT, -- Store AI analysis here
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    )");

    if (!success) {
        qCritical() << "❌ Failed to create 'sentences' table:" << query.lastError().text();
        return false;
    } else {
        qDebug() << "✅ 'sentences' table created or already exists";
    }

    if (!createWordProfilesTable()) {
        return false;
    }
    if (!createLinkingTables()) {
        return false;
    }

    return success;
}

bool DatabaseManager::createLinkingTables() {
    QSqlQuery query(m_db);
    bool success = query.exec(R"(
    CREATE TABLE sentence_word_links (
        sentence_id INTEGER NOT NULL,
        word_id INTEGER NOT NULL,
        FOREIGN KEY(sentence_id) REFERENCES sentences(id),
        FOREIGN KEY(word_id) REFERENCES word_profiles(id),
        PRIMARY KEY (sentence_id, word_id)
    );
    )");

    return success;
}




bool DatabaseManager::createWordProfilesTable() {
    QSqlQuery query(m_db);

    // words for practice, not explorer.
    const QString createTableSql = R"(
        CREATE TABLE IF NOT EXISTS word_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT COLLATE NOCASE,
            type TEXT DEFAULT "verb",
            ai_response TEXT,
            context TEXT,
            encounter_count INTEGER NOT NULL DEFAULT 1,
            last_encounter_timestamp DATETIME NOT NULL DEFAULT (datetime('now')),
            first_encounter_timestamp DATETIME NOT NULL DEFAULT (datetime('now')),
            next_review_timestamp DATETIME,
            review_interval_seconds INTEGER,
            ease_factor REAL,
            reviewed_count INTEGER NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT (datetime('now')),
            updated_at DATETIME NOT NULL DEFAULT (datetime('now'))
        )
    )";


    bool success = query.exec(createTableSql);

    if (!success) {
        qCritical() << "❌ Failed to create 'word_profiles' table:" << query.lastError().text();
    } else {
        qDebug() << "✅ 'word_profiles' table created or already exists";

        // --- Optional: Add indexes for performance ---
        // Index on encounter_count for sorting by rarity/frequency
        query.exec("CREATE INDEX IF NOT EXISTS idx_word_encounter_count ON word_profiles(encounter_count);");

        // Index on last_encounter_timestamp for sorting by recent
        query.exec("CREATE INDEX IF NOT EXISTS idx_word_last_encounter ON word_profiles(last_encounter_timestamp);");

        // Index on next_review_timestamp for finding words due for review
        query.exec("CREATE INDEX IF NOT EXISTS idx_word_next_review ON word_profiles(next_review_timestamp);");

        qDebug() << "✅ Indexes for 'word_profiles' ensured";
    }

    return success;
}


bool DatabaseManager::addEntry(const QString &text, const QVariantMap &metadata) {
    if (text.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare("INSERT INTO sentences (text, metadata) VALUES (?, ?)");
    query.addBindValue(text);
    QJsonDocument doc = QJsonDocument::fromVariant(metadata);
    QString metadataJson = doc.toJson(QJsonDocument::Compact);
    query.addBindValue(metadataJson);

    bool success = query.exec();
    if (success) {
        qDebug() << "📥 Saved to database " << "Text:" << text;
    } else {
        qWarning() << "❌ Failed to save to database.";
        qWarning() << "   Error:" << query.lastError().text();
        qWarning() << "   Query:" << query.lastQuery();
    }
    emit queueChanged();
    return success;
}



bool DatabaseManager::createWordProfile(const QString &word, const QString &context, const QString &ai_response) {
    if (word.isEmpty()) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare("INSERT INTO word_profiles (word, ai_response, context) VALUES (?, ?, ?)");
    query.addBindValue(word);
    query.addBindValue(ai_response);
    query.addBindValue(context);

    bool success = query.exec();
    if (success) {
        qDebug() << "📥 Saved word profile to database: " << word;
    } else {
        qWarning() << "❌ Failed to save word profile to database.";
        qWarning() << "   Error:" << query.lastError().text();
        qWarning() << "   Query:" << query.lastQuery();
    }
    return success;
}


void DatabaseManager::discardSentence(int id) {
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM sentences WHERE id = ?");
    query.addBindValue(id);
    query.exec();
}

void DatabaseManager::markToProcessSentence(int id, const QString &formattedText) {
    QSqlQuery query(m_db);
    // this is for after Queue. pending... waiting for AI to get it and process
    query.prepare("UPDATE sentences SET processed = 1, text = ? WHERE id = ?");
    query.addBindValue(formattedText);
    query.addBindValue(id);
    if (!query.exec()) {
        qWarning() << "❌ Failed to mark sentence as pending:" << query.lastError().text();
    } else {
        qDebug() << "✅ Marked sentence ID" << id << "as pending with formatted text";
    }
    emit sentenceMarkedForProcessing(id, formattedText);
}



void DatabaseManager::updateSentenceWithAIAnalysis(int id, const QString &response) {
    QSqlQuery query(m_db);
    query.prepare("UPDATE sentences SET processed = 2, ai_response = ? WHERE id = ?");
    query.addBindValue(response);
    query.addBindValue(id);
    if (!query.exec()) {
        qWarning() << "❌ Failed to mark sentence as completed:" << query.lastError().text();
    } else {
        qDebug() << "✅ Marked sentence ID" << id << "as completed with AI response";
    }
}




QVariantList DatabaseManager::getQueueEntries(int limit){
    QVariantList result;
    QSqlQuery query(m_db);
    query.prepare("SELECT id, text FROM sentences WHERE processed = 0 ORDER BY id ASC LIMIT ?");
    query.addBindValue(limit);
    if (query.exec()) {
        while (query.next()) {
            QVariantMap item;
            item["id"] = query.value(0).toInt();
            item["text"] = query.value(1).toString();
            result.append(item);
        }
    }
    return result;
}

QVariantList DatabaseManager::getExplorerEntries(int limit){
    QVariantList result;
    QSqlQuery query(m_db);
    query.prepare("SELECT id, text FROM sentences WHERE processed = 2 ORDER BY id DESC LIMIT ?");
    query.addBindValue(limit);
    if (query.exec()) {
        while (query.next()) {
            QVariantMap item;
            item["id"] = query.value(0).toInt();
            item["text"] = query.value(1).toString();
            result.append(item);
        }
    }
    return result;
}



int DatabaseManager::getQueueCount(){
    QSqlQuery query(m_db);
    query.prepare("SELECT COUNT(*) FROM sentences WHERE processed = 0 ");
    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }
    return 0;
}



QVariantMap DatabaseManager::getSentencesProfile(const int id) {
    QVariantMap result;
    QSqlQuery query(m_db);
    query.prepare("SELECT id, text, metadata, processed, ai_response FROM sentences WHERE id = ?");
    query.addBindValue(id);

    if (query.exec() && query.next()) {
        result["id"] = query.value("id").toInt();
        result["text"] = query.value("text").toString();
        result["metadata"] = query.value("metadata").toString();
        result["processed"] = query.value("processed").toInt();
        result["ai_response"] = query.value("ai_response").toString();
    } else {
        qWarning() << "❌ Database error fetching sentence profile:" << query.lastError().text();
    }
    return result;
}



QVariantList DatabaseManager::getWords() {
    QVariantList words;
    QSqlQuery query(m_db);
    query.prepare("SELECT id, word, type FROM word_profiles ORDER by id DESC"); // assuming you have these columns

    if (!query.exec()) {
        qWarning() << "❌ Database error fetching words:" << query.lastError().text();
        return words;
    }

    while (query.next()) {
        QVariantMap entry;
        entry["idNum"] = query.value("id").toInt();
        entry["vocab"] = query.value("word").toString();
        entry["type"] = query.value("type").toString(); // e.g. noun/verb/adjective
        words.append(entry);
    }
    return words;
}




QVariantMap DatabaseManager::getWordProfile(const int id) {
    QSqlQuery query(m_db);
    QVariantMap result;
    query.prepare("SELECT id, word, context, ai_response FROM word_profiles WHERE id = ?");
    query.addBindValue(id);

    if (query.exec() && query.next()) {
        result["id"] = query.value("id").toInt();
        result["word"] = query.value("word").toString();
        result["ai_response"] = query.value("ai_response").toString();
        result["context"] = query.value("context").toString();
    } else {
        qWarning() << "❌ Database error fetching sentence profile:" << query.lastError().text();
    }
    return result;
}



bool DatabaseManager::deleteSentence(const int id) {
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM sentences WHERE id = ?");
    query.addBindValue(id);
    bool success = query.exec();
    if (!success) {
        qWarning() << "❌ Failed to delete word profile for" << id << ":" << query.lastError().text();
    } else {
        qDebug() << "🗑️ Deleted word profile for:" << id;
    }
    return success;
}


bool DatabaseManager::deleteWord(const int id) {
    QSqlQuery query(m_db);
    query.prepare("DELETE FROM word_profiles WHERE id = ?");
    query.addBindValue(id);
    bool success = query.exec();
    if (!success) {
        qWarning() << "❌ Failed to delete word profile for" << id << ":" << query.lastError().text();
    } else {
        qDebug() << "🗑️ Deleted word profile for:" << id;
    }
    return success;
}


bool DatabaseManager::updateWordProfile(int id, const QString &profileData) {
    QSqlQuery query(m_db);
    query.prepare("UPDATE word_profiles SET ai_response = ? WHERE id = ?");
    query.addBindValue(profileData);
    query.addBindValue(id);

    bool success = query.exec();
    if (success) {
        qDebug() << "🔄 Updated word profile ID:" << id;
    } else {
        qWarning() << "❌ Failed to update word profile ID:" << id;
        qWarning() << "   Error:" << query.lastError().text();
    }
    return success;
}


// // --- Example: Function to get words for review (due or random) ---
// QList<QVariantMap> DatabaseManager::getWordsForReview(int limit, bool onlyDue) {
//     QSqlQuery query(m_db);
//     QString sql;

//     if (onlyDue) {
//         // Get words where next_review_timestamp is in the past or null (new words)
//         sql = R"(
//             SELECT * FROM word_profiles
//             WHERE next_review_timestamp IS NULL OR next_review_timestamp <= datetime('now')
//             ORDER BY next_review_timestamp ASC NULLS FIRST -- New words (NULL) first, then overdue
//             LIMIT ?
//         )";
//     } else {
//         // Get a random sample of words (e.g., least encountered, or just random)
//         // Example: Least encountered first
//         sql = R"(
//             SELECT * FROM word_profiles
//             ORDER BY encounter_count ASC, RANDOM() -- Mix it up a bit
//             LIMIT ?
//         )";
//         // Or purely random:
//         // sql = "SELECT * FROM word_profiles ORDER BY RANDOM() LIMIT ?";
//     }

//     query.prepare(sql);
//     query.addBindValue(limit);

//     QList<QVariantMap> results;
//     if (query.exec()) {
//         while (query.next()) {
//             QVariantMap row;
//             for (int i = 0; i < query.record().count(); ++i) {
//                 row.insert(query.record().fieldName(i), query.value(i));
//             }
//             results.append(row);
//         }
//     } else {
//         qWarning() << "Failed to query words for review:" << query.lastError();
//     }
//     return results;
// }




// QList<QPair<int, QString>> DatabaseManager::getPendingSentences() {
//     QList<QPair<int, QString>> result;
//     QSqlQuery query(m_db);
//     if (query.exec("SELECT id, text FROM sentences WHERE sent = 1")) {
//         while (query.next()) {
//             int id = query.value(0).toInt();
//             QString text = query.value(1).toString();
//             result.append(qMakePair(id, text));
//         }
//     }
//     return result;
// }

// void DatabaseManager::markSentenceAsSent(int id) {
//     QString api_key = SettingsManager::instance()->getValue("auth_token", "").toString();
//     QSqlQuery query(m_db);
//     query.prepare("UPDATE sentences SET sent = 2 WHERE id = ? AND api_key = ?");
//     query.addBindValue(id);
//     query.addBindValue(api_key);
//     query.exec();
// }

// bool DatabaseManager::saveWordProfile(const QString &word, const QVariantMap &profileData) {
//     QSqlQuery query(m_db);
//     query.prepare("INSERT OR REPLACE INTO word_profiles (word, profile_data) VALUES (?, ?)");
//     query.addBindValue(word);

//     QJsonDocument doc = QJsonDocument::fromVariant(profileData);
//     QString profileJson = doc.toJson(QJsonDocument::Compact);
//     query.addBindValue(profileJson);

//     bool success = query.exec();
//     if (!success) {
//         qWarning() << "❌ Failed to save word profile for" << word << ":" << query.lastError().text();
//     } else {
//         qDebug() << "💾 Saved word profile for:" << word;
//     }
//     return success;
// }

// // --- NEW --- Get a word profile



// QStringList DatabaseManager::getAllWords() {
//     QStringList words;
//     QSqlQuery query(m_db);
//     if (query.exec("SELECT word FROM word_profiles ORDER BY word")) {
//         while (query.next()) {
//             words << query.value("word").toString();
//         }
//     }
//     if (query.lastError().isValid()) {
//         qWarning() << "❌ Database error fetching word list:" << query.lastError().text();
//     }
//     return words;
// }


// bool DatabaseManager::updateWordProfile(const QString &word, const QVariantMap &updatedProfileData) {
//     return saveWordProfile(word, updatedProfileData);
// }

// Q_INVOKABLE QVariantList DatabaseManager::getWordProfiles(int limit) {
//     QVariantList result;
//     QSqlQuery query(m_db); // Use the member database connection
//     query.prepare("SELECT word, profile_data FROM word_profiles LIMIT ?");
//     query.addBindValue(limit);

//     if (query.exec()) {
//         while (query.next()) {
//             QVariantMap wordData;
//             QString word = query.value(0).toString();
//             QString profileDataJsonString = query.value(1).toString();

//             wordData["word"] = word;

//             // Parse the JSON profile_data
//             QJsonParseError parseError;
//             QJsonDocument doc = QJsonDocument::fromJson(profileDataJsonString.toUtf8(), &parseError);
//             if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
//                 // Convert the JSON object directly into a QVariantMap
//                 QVariantMap profileMap = doc.object().toVariantMap();
//                 // Merge the profile data into the main wordData map
//                 // This allows QML to access profile fields like wordData.definition
//                 for (auto it = profileMap.constBegin(); it != profileMap.constEnd(); ++it) {
//                     wordData.insert(it.key(), it.value());
//                 }
//             } else {
//                 // If JSON is invalid or not an object, log a warning and/or add a placeholder
//                 qWarning() << "Failed to parse profile_data JSON for word:" << word << parseError.errorString();
//                 // Optionally add an error flag or message
//                 // wordData["profile_parse_error"] = parseError.errorString();
//             }

//             result.append(wordData);
//         }
//     } else {
//         qWarning() << "Failed to execute getWordProfiles query:" << query.lastError().text();
//     }

//     return result;
// }


// // --- New Helper: Check if table is empty ---
// bool DatabaseManager::isWordProfilesTableEmpty() {
//     QSqlQuery query(m_db);
//     if (!query.exec("SELECT COUNT(*) FROM word_profiles")) {
//         qWarning() << "Failed to count rows in word_profiles:" << query.lastError().text();
//         return false; // Assume not empty or error occurred
//     }
//     if (query.next()) {
//         int count = query.value(0).toInt();
//         return count == 0;
//     }
//     return false; // Shouldn't happen, but assume not empty
// }

