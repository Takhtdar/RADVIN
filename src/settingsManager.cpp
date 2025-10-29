// settingsManager.cpp
#include "settingsManager.h"
#include <QSettings>


SettingsManager *SettingsManager::instance() {
    static SettingsManager instance;
    return &instance;
}

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
    , m_settings("Radvin", "Reader") // Organization, App name
{
}


void SettingsManager::setValue(const QString &key, const QVariant &value) {
    m_settings.setValue(key, value);
    emit settingChanged(key); // ✅ NEW: Notify listeners
}

QVariant SettingsManager::getValue(const QString &key, const QVariant &defaultValue) const {
    return m_settings.value(key, defaultValue);
}

void SettingsManager::remove(const QString &key) {
    m_settings.remove(key);
}

bool SettingsManager::contains(const QString &key) const {
    return m_settings.contains(key);
}

void SettingsManager::sync() {
    m_settings.sync();
}


