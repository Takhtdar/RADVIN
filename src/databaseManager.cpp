#include "databaseManager.h"
#include <QDebug>
#include <QSqlQuery>
#include <QSqlError>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QSqlRecord>
#include <QFile>
#include <QTextStream>
#include <QFileInfo>
#include <QUrl>




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
        ai_response TEXT, -- Store AI analysis here explanation
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
            type TEXT, -- DEFAULT "verb"
            ai_response TEXT,
            context TEXT,
            definition TEXT,
            example_sentences TEXT,
            synonyms TEXT,
            antonyms TEXT,
            note TEXT, -- user notes
            processed INTEGER DEFAULT 0,
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
    if (text.trimmed().isEmpty())
        return false;

    const bool isSingleWord = !text.trimmed().contains(' ');

    QSqlQuery query(m_db);

    if (isSingleWord) {
        query.prepare("INSERT INTO word_profiles (word) VALUES (?)");
        query.addBindValue(text);
    } else {
        query.prepare("INSERT INTO sentences (text, metadata) VALUES (?, ?)");
        query.addBindValue(text);

        QJsonDocument doc = QJsonDocument::fromVariant(metadata);
        QString metadataJson = doc.toJson(QJsonDocument::Compact);
        query.addBindValue(metadataJson);
    }

    bool success = query.exec();
    emit queueChanged();
    return success;
}



bool DatabaseManager::importTextFile(const QString &filePathFromQml)
{
    QUrl url(filePathFromQml);
    QString localPath = url.isLocalFile()
                            ? url.toLocalFile()
                            : filePathFromQml;

    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open file:" << localPath;
        return false;
    }

    QTextStream in(&file);
    QVariantMap metadata;
    metadata["source"] = QFileInfo(localPath).fileName();

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (!line.isEmpty())
            addEntry(line, metadata);
    }

    return true;
}




// mark for delete
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


int DatabaseManager::insertWordProfile(const QString &word, const QString &context) {
    QSqlQuery q(m_db);
    q.prepare(R"(
        INSERT INTO word_profiles (word, context, processed, created_at, updated_at)
        VALUES (?, ?, 1, datetime('now'), datetime('now'))
    )");
    q.addBindValue(word);
    q.addBindValue(context);
    if (!q.exec()) {
        qWarning() << "insertWordProfile failed:" << q.lastError().text();
        return -1;
    }
    int id = q.lastInsertId().toInt();
    //emit queueChanged();
    return id;
}



void DatabaseManager::updateWordProfileType(int id, const QString &type)
{
    QSqlQuery q(m_db);
    q.prepare(R"(
        UPDATE word_profiles SET
            type = ?, processed = 2, updated_at = datetime('now')
        WHERE id = ?
    )");
    q.addBindValue(type);
    q.addBindValue(id);
    if (!q.exec()) qWarning() << "updateWordProfileStructured failed:" << q.lastError().text();
    else qDebug() << "Word profile updated structured id:" << id;
    // emit queueChanged();
}





void DatabaseManager::discardQueueItem(int id, const QString &type) {
    QSqlQuery query(m_db);
    if (type == "sentence") {
        query.prepare("DELETE FROM sentences WHERE id = ?");
    } else if (type == "word") {
        query.prepare("DELETE FROM word_profiles WHERE id = ?");
    } else {
        qWarning() << "Unknown type for discard:" << type;
        return;
    }
    query.addBindValue(id);
    query.exec();
}


void DatabaseManager::markQueueItemToProcess(int id, const QString &formattedText, const QString &itemType) {
    QSqlQuery query(m_db);

    if (itemType == "sentence") {
        query.prepare("UPDATE sentences SET processed = 1, text = ? WHERE id = ?");
    } else if (itemType == "word") {
        query.prepare("UPDATE word_profiles SET processed = 1, ai_response = ? WHERE id = ?");
    } else {
        qWarning() << "❌ Unknown item type for markQueueItemToProcess:" << itemType;
        return;
    }

    query.addBindValue(formattedText);
    query.addBindValue(id);

    if (!query.exec()) {
        qWarning() << "❌ Failed to mark item as pending:" << query.lastError().text();
    } else {
        qDebug() << "✅ Marked" << itemType << "ID" << id << "as pending";
    }

    emit queueItemMarkedForProcessing(id, itemType, formattedText);
}




void DatabaseManager::updateSentenceWithAIAnalysis(int id, const QString &response) {
    QSqlQuery query(m_db);
    // later change it to explanation
    query.prepare("UPDATE sentences SET processed = 2, ai_response = ? WHERE id = ?");
    query.addBindValue(response);
    query.addBindValue(id);
    if (!query.exec()) {
        qWarning() << "❌ Failed to mark sentence as completed:" << query.lastError().text();
    } else {
        qDebug() << "✅ Marked sentence ID" << id << "as completed with AI response";
    }
}

void DatabaseManager::updateWordProfileWithAIFallback(int id, const QString &rawResponse) {
    QSqlQuery q(m_db);
    q.prepare("UPDATE word_profiles SET ai_response = ?, processed = 2, updated_at = datetime('now') WHERE id = ?");
    q.addBindValue(rawResponse);
    q.addBindValue(id);
    if (!q.exec()) qWarning() << "updateWordProfileWithAIFallback failed:" << q.lastError().text();
    else qDebug() << "Word profile updated (fallback) id:" << id;
    // emit queueChanged();
}




QVariantList DatabaseManager::getQueueEntries(int limit){
    QVariantList result;
    QSqlQuery query(m_db);
    query.prepare(R"(
        SELECT id, word AS text, 'word' AS type FROM word_profiles WHERE processed = 0
        UNION ALL
        SELECT id, text, 'sentence' AS type FROM sentences WHERE processed = 0
        ORDER BY id ASC
        LIMIT ?
    )");
    query.addBindValue(limit);

    if (query.exec()) {
        while (query.next()) {
            QVariantMap item;
            item["id"] = query.value(0).toInt();
            item["text"] = query.value(1).toString();
            item["type"] = query.value(2).toString();
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
    query.prepare(R"(
        SELECT COUNT(*) FROM (
            SELECT id FROM sentences WHERE processed = 0
            UNION ALL
            SELECT id FROM word_profiles WHERE processed = 0
        )
    )");
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
        entry["id"] = query.value("id").toInt();
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


