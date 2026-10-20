#pragma once

#include <QObject>
#include <QPointer>
#include <QVariantList>
#include <QWindow>
#include <QtQml/qqmlregistration.h>

class BlurHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QWindow *window READ window WRITE setWindow NOTIFY windowChanged)
    Q_PROPERTY(QVariantList tiles READ tiles WRITE setTiles NOTIFY tilesChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)

public:
    explicit BlurHelper(QObject *parent = nullptr);
    ~BlurHelper() override;

    QWindow *window() const { return m_window; }
    void setWindow(QWindow *window);

    QVariantList tiles() const { return m_tiles; }
    void setTiles(const QVariantList &tiles);

    bool active() const { return m_active; }
    void setActive(bool active);

    // Schedules a (coalesced) recompute of the blur region
    Q_INVOKABLE void update();

Q_SIGNALS:
    void windowChanged();
    void tilesChanged();
    void activeChanged();

private:
    void apply();

    QPointer<QWindow> m_window;
    QVariantList m_tiles;
    bool m_active = true;
    bool m_pending = false;
};
