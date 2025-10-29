#ifndef CLIPBOARDLISTENER_H
#define CLIPBOARDLISTENER_H

#include <QObject>
#include <QClipboard>
#include <QTimer>
#include <QGuiApplication>

class ClipboardListener : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString text READ text NOTIFY textChanged)

public:
    explicit ClipboardListener(QObject *parent = nullptr);

    QString text() const { return m_lastText; }
    void stop();


signals:
    void textCopied(const QString &text);
    void textChanged();
    void clipboardSaved(); // port this later to database


public slots:
    void start();
    void onClipboardChanged();
    void setEnabled(bool enabled);


private:
    QString filterText(const QString &text);

    QClipboard *m_clipboard;
    QString m_lastText;
    QTimer *m_timer;
    bool m_enabled = true;

};

#endif // CLIPBOARDLISTENER_H
