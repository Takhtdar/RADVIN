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
    Q_INVOKABLE void discardSentence(int id);


    Q_INVOKABLE QVariantList getExplorerEntries(int limit = 100);
    Q_INVOKABLE void markToProcessSentence(int id, const QString &formattedText);

    Q_INVOKABLE QVariantMap getWordProfile(const int id);

    Q_INVOKABLE bool deleteSentence(const int id);


    Q_INVOKABLE QVariantMap getSentencesProfile(const int id);


    void updateSentenceWithAIAnalysis(int id, const QString &response);

    Q_INVOKABLE QVariantList getWords();


     Q_INVOKABLE bool deleteWord(const int id);


     Q_INVOKABLE bool updateWordProfile(int id, const QString &profileData);



    // Q_INVOKABLE int getSentenceCount() const;
    // QList<QPair<int, QString>> getPendingSentences();
    // Q_INVOKABLE void markSentenceAsSent(int id);

    // Q_INVOKABLE bool saveWordProfile(const QString &word, const QVariantMap &profileData);
    // Q_INVOKABLE QVariantList getWordProfiles(int limit = 10);
    // Q_INVOKABLE QStringList getAllWords();
    // Q_INVOKABLE bool deleteWordProfile(const QString &word);
    // Q_INVOKABLE bool updateWordProfile(const QString &word, const QVariantMap &updatedProfileData);
    // bool recordWordEncounter(const QString &word, const QVariantMap &contextMetadata);
    // QList<QVariantMap> getWordsForReview(int limit, bool onlyDue);

signals:
    void sentenceMarkedForProcessing(int sentenceId, const QString &formattedText);
    void queueChanged();

private:
    QSqlDatabase m_db;
    bool createTables();
    bool isWordProfilesTableEmpty();
    bool createWordProfilesTable();
    bool createLinkingTables();




};

#endif // DATABASEMANAGER_H
