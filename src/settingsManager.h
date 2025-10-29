// settingsManager.h
#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QSettings>

class SettingsManager : public QObject {
    Q_OBJECT

public:
    // ✅ Singleton getter
    static SettingsManager *instance();

    // QML-accessible methods
    Q_INVOKABLE void setValue(const QString &key, const QVariant &value);
    Q_INVOKABLE QVariant getValue(const QString &key, const QVariant &defaultValue = QVariant()) const;
    Q_INVOKABLE void remove(const QString &key);
    Q_INVOKABLE bool contains(const QString &key) const;
    Q_INVOKABLE void sync(); // Force save to disk

signals:
    void settingChanged(const QString &key); // ✅ NEW: Notify when setting changes


private:
    explicit SettingsManager(QObject *parent = nullptr);
    QSettings m_settings;

    // ✅ Disable copy constructor and assignment operator
    SettingsManager(const SettingsManager &) = delete;
    SettingsManager &operator=(const SettingsManager &) = delete;

};

#endif // SETTINGSMANAGER_H
