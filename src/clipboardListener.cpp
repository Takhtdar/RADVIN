#include "clipboardListener.h"
#include <QDebug>
#include <QRegularExpression>
#include <QDateTime>

ClipboardListener::ClipboardListener(QObject *parent)
    : QObject(parent)
    , m_clipboard(QGuiApplication::clipboard())
    , m_lastText("")
    , m_timer(new QTimer(this))
    , m_enabled(false)
{
    connect(m_clipboard, &QClipboard::dataChanged, this, &ClipboardListener::onClipboardChanged);

    m_timer->setInterval(2000);
    connect(m_timer, &QTimer::timeout, this, &ClipboardListener::onClipboardChanged);
    m_timer->start();
}

void ClipboardListener::start() {
    if (m_enabled) {
        m_timer->start();
        qDebug() << "✅ Clipboard listener STARTED";
    } else {
        qDebug() << "🔒 Clipboard listener is DISABLED - not starting";
    }
}

void ClipboardListener::onClipboardChanged() {
    if (!m_enabled) {
        // qDebug() << "🔒 Clipboard listener is DISABLED — ignoring clipboard change";
        return;
    }

    const QString rawText = m_clipboard->text();
    if (!rawText.isEmpty() && rawText != m_lastText) {
        QString filteredText = filterText(rawText);
        if (!filteredText.isEmpty()) {
            m_lastText = rawText;
            emit textCopied(filteredText);
            emit textChanged();
            qDebug() << "Filtered Copied Text:" << filteredText;
        }
    }
}

QString ClipboardListener::filterText(const QString &text) {
    // ✅ Skip if empty or just whitespace
    QString trimmed = text.trimmed();
    if (trimmed.isEmpty()) return QString();

    // ✅ Skip if it's a URL
    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
        qDebug() << "Skipping URL:" << trimmed;
        return QString();
    }

    // ✅ Skip if it looks like binary or file path
    if (trimmed.contains('\0') || trimmed.contains(QRegularExpression(R"(^[/\w]:[\\/])"))) {
        qDebug() << "Skipping binary or file path:" << trimmed;
        return QString();
    }

    // ✅ Collapse multiple spaces and tabs into single space
    QString clean = trimmed;
    clean.replace(QRegularExpression("\\s+"), " ");
    // in case it has break lines remove them and turn them into single line

    // ✅ Skip if too long (>200 words)
    QStringList words = clean.split(' ', Qt::SkipEmptyParts);
    if (words.size() > 200) {
        qDebug() << "Skipping long text (" << words.size() << " words)";
        return QString();
    }

    return clean;
}

void ClipboardListener::setEnabled(bool enabled) {
    if (m_enabled == enabled) return;

    m_enabled = enabled;
    if (m_enabled) {
        start();
    } else {
        stop();
    }
    qDebug() << "📎 Clipboard listener set to:" << (m_enabled ? "ENABLED" : "DISABLED");
}


void ClipboardListener::stop() {
    m_timer->stop();
    qDebug() << "🛑 Clipboard listener STOPPED";
}



