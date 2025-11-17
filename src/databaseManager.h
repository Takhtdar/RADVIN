#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QtSql/QSqlDatabase>
#include <QPair>
#include <QList>
#include <QVariantMap>

class DatabaseManager : public QObject {
    Q_OBJECT

public:
    explicit DatabaseManager(const QString &path, QObject *parent = nullptr);

    Q_INVOKABLE bool addEntry(const QString &text, const QVariantMap &metadata);
    Q_INVOKABLE bool createWordProfile(const QString &word, const QString &context, const QString &ai_response);

    Q_INVOKABLE QVariantList getQueueEntries(int limit = 100);
    Q_INVOKABLE int getQueueCount();
    Q_INVOKABLE void discardQueueItem(int id, const QString &type);


    Q_INVOKABLE QVariantList getExplorerEntries(int limit = 100);
    Q_INVOKABLE void markQueueItemToProcess(int id, const QString &formattedText, const QString &itemType);

    Q_INVOKABLE QVariantMap getWordProfile(const int id);

    Q_INVOKABLE bool deleteSentence(const int id);


    Q_INVOKABLE QVariantMap getSentencesProfile(const int id);


    void updateSentenceWithAIAnalysis(int id, const QString &response);
    void updateWordProfileWithAIFallback(int id, const QString &rawResponse);

    Q_INVOKABLE QVariantList getWords();


     Q_INVOKABLE bool deleteWord(const int id);


     Q_INVOKABLE bool updateWordProfile(int id, const QString &profileData);

     int insertWordProfile(const QString &word, const QString &context);
     void updateWordProfileStructured(int id,
                                 const QString &type, const QString &definition, const QString &examples,
                                 const QString &synonyms, const QString &antonyms);


signals:
    void queueItemMarkedForProcessing(int id, const QString &formattedText, const QString &itemType);
    void queueChanged();

private:
    QSqlDatabase m_db;
    bool createTables();
    bool isWordProfilesTableEmpty();
    // mark for delete

    bool createWordProfilesTable();

    bool createLinkingTables();




};

#endif // DATABASEMANAGER_H
