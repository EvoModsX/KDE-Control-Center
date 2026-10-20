#include "blurhelper.h"

#include <KWindowEffects>
#include <QQuickItem>
#include <QRegion>
#include <QtMath>

// Approximates a rounded rect as a QRegion made of 1px-high scanline rects.
static QRegion roundedRegion(const QRectF &rf, qreal radius)
{
    const QRect rect = rf.toRect();
    if (rect.isEmpty())
        return {};

    const int r = qMin(qRound(radius), qMin(rect.width(), rect.height()) / 2);
    if (r <= 0)
        return QRegion(rect);

    QRegion region;
    // Straight middle section
    region += QRect(rect.x(), rect.y() + r, rect.width(), rect.height() - 2 * r);

    // Top and bottom rounded caps
    for (int i = 0; i < r; ++i) {
        const qreal dy = r - i - 0.5;
        const int inset = qRound(r - qSqrt(qMax(0.0, r * r - dy * dy)));
        const int w = rect.width() - 2 * inset;
        if (w <= 0)
            continue;
        region += QRect(rect.x() + inset, rect.y() + i, w, 1);
        region += QRect(rect.x() + inset, rect.y() + rect.height() - 1 - i, w, 1);
    }
    return region;
}

BlurHelper::BlurHelper(QObject *parent)
: QObject(parent)
{
}

BlurHelper::~BlurHelper()
{
    if (m_window)
        KWindowEffects::enableBlurBehind(m_window, false);
}

void BlurHelper::setWindow(QWindow *window)
{
    if (m_window == window)
        return;
    if (m_window)
        KWindowEffects::enableBlurBehind(m_window, false);
    m_window = window;
    Q_EMIT windowChanged();
    update();
}

void BlurHelper::setTiles(const QVariantList &tiles)
{
    m_tiles = tiles;
    Q_EMIT tilesChanged();
    update();
}

void BlurHelper::setActive(bool active)
{
    if (m_active == active)
        return;
    m_active = active;
    Q_EMIT activeChanged();
    update();
}

void BlurHelper::update()
{
    if (m_pending)
        return;
    m_pending = true;
    QMetaObject::invokeMethod(this, &BlurHelper::apply, Qt::QueuedConnection);
}

void BlurHelper::apply()
{
    m_pending = false;
    if (!m_window)
        return;

    QRegion region;
    if (m_active) {
        for (const QVariant &v : std::as_const(m_tiles)) {
            auto *item = qobject_cast<QQuickItem *>(v.value<QObject *>());
            if (!item || !item->isVisible() || item->width() <= 0)
                continue;

            // mapRectToScene includes parent transforms (your scale animation)
            const QRectF r = item->mapRectToScene(QRectF(0, 0, item->width(), item->height()));
            const qreal scale = r.width() / item->width();
            const qreal radius = item->property("radius").toReal() * scale;
            region += roundedRegion(r, radius);
        }
    }

    // NOTE: an empty region means "blur the whole window" to KWin,
    // so we must disable blur explicitly instead.
    if (region.isEmpty())
        KWindowEffects::enableBlurBehind(m_window, false);
    else
        KWindowEffects::enableBlurBehind(m_window, true, region);
}
