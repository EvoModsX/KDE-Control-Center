import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: sTile
    property var dialogRoot
    property var contentWrapper
    property var blurHelper

    property string tileKey: ""
    property bool inDrawer: false
    property int drawerCol: 0
    property int drawerRow: 0
    property int gridCol: 0
    property int gridRow: 0
    property int spanCols: 1
    property int spanRows: 2

    property real currentRatio: 0.5
    property string iconSource: ""
    property string tooltipText: ""
    property bool clampBottom: false

    // "fill"  = iOS style, the whole tile fills up (clipped to the tile's rounded shape)
    // "mac"   = macOS Control Center style: title + slim pill track (sideways)
    // "slim"  = sideways thin track with a round knob
    // "slimV" = upright thin track with a round knob
    property string sliderStyle: "fill"
    property string titleText: tooltipText
    readonly property bool isFill: sliderStyle === "fill"
    readonly property bool isMac: sliderStyle === "mac"

    property bool isHorizontal: spanCols > spanRows

    signal ratioSet(real ratio)
    signal ratioReleased(real ratio)

    readonly property real targetX: inDrawer ? contentWrapper.getDrawerX(drawerCol) : contentWrapper.getGridX(gridCol)
    readonly property real targetY: inDrawer ? contentWrapper.getDrawerY(drawerRow) : contentWrapper.getGridY(gridRow)
    readonly property real targetW: contentWrapper.getGridW(spanCols)
    readonly property real targetH: contentWrapper.getGridH(spanRows)

    property bool isDragging: false
    property real dragX: targetX
    property real dragY: targetY
    x: isDragging ? dragX : targetX
    y: isDragging ? dragY : targetY
    width: targetW
    height: targetH
    z: isDragging ? 999 : 1
    visible: !inDrawer || contentWrapper.drawerAnimProgress > 0

    Behavior on x {
        enabled: !sTile.isDragging && dialogRoot.visible
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutBack
            easing.overshoot: 1.02
        }
    }
    Behavior on y {
        enabled: !sTile.isDragging && dialogRoot.visible
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutBack
            easing.overshoot: 1.02
        }
    }

    radius: dialogRoot.cfgRadius
    color: dialogRoot.tileBaseColor
    border.color: dialogRoot.editMode ? Qt.rgba(1, 1, 1, 0.35) : dialogRoot.tileBorderColor
    border.width: dialogRoot.tileBorderWidth
    clip: false

    property bool isSliderPressed: sliderMouse.pressed
    property real hoverScale: (sliderMouse.containsMouse || isSliderPressed) ? 1.015 : 1.0
    Behavior on hoverScale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    scale: (dialogRoot.animStyle === 2 ? 1.0 : (isDragging ? 1.03 : 1.0) * animProgress) * hoverScale
    transformOrigin: dialogRoot.isBottomLeft ? Item.BottomLeft : Item.BottomRight
    onScaleChanged: { if(blurHelper) blurHelper.update() }
    onXChanged: { if(blurHelper) blurHelper.update() }
    onYChanged: { if(blurHelper) blurHelper.update() }

    readonly property real deltaX: dialogRoot.isBottomLeft ? -targetX : (contentWrapper.width - (targetX + targetW))
    readonly property real deltaY: contentWrapper.height - (targetY + targetH)

    transform: Translate {
        x: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - sTile.animProgress) * sTile.deltaX
        y: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - sTile.animProgress) * sTile.deltaY
    }

    property real baseOpacity: 0.0
    property real animProgress: 0.0
    property int animDelay: 0
    property alias enterAnim: stEnter
    property alias dismissAnim: stDismiss

    opacity: inDrawer ? (baseOpacity * contentWrapper.drawerAnimProgress) : baseOpacity

    SequentialAnimation {
        id: stEnter
        PauseAnimation { duration: sTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: sTile
                property: "baseOpacity"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 380) / dialogRoot.speedMultiplier)
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: sTile
                property: "animProgress"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 620) / dialogRoot.speedMultiplier)
                easing.type: dialogRoot.animStyle === 0 ? Easing.OutBack : Easing.OutCubic
                easing.overshoot: dialogRoot.animStyle === 0 ? 1.004 : 1.0
            }
        }
    }
    SequentialAnimation {
        id: stDismiss
        PauseAnimation { duration: sTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: sTile
                property: "animProgress"
                to: 0.0
                duration: Math.round(160 / dialogRoot.speedMultiplier)
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: sTile
                property: "baseOpacity"
                to: 0.0
                duration: Math.round(130 / dialogRoot.speedMultiplier)
                easing.type: Easing.InQuad
            }
        }
    }
    function triggerAnim(entering, delay) {
        animDelay = delay
        stEnter.stop()
        stDismiss.stop()
        if (entering) {
            baseOpacity = 0.0
            animProgress = 0.0
            stEnter.start()
        } else {
            stDismiss.start()
        }
    }

    shadow {
        size: dialogRoot.showShadow ? (sTile.isDragging ? dialogRoot.computedShadowSize + 12 : dialogRoot.computedShadowSize) : 0
        color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
        xOffset: 0
        yOffset: 0
    }

    Timer {
        id: debounceTimer
        interval: 40
        repeat: false
        property real pendingVal: 0.5
        onTriggered: sTile.ratioSet(pendingVal)
    }

    // ===================== STYLE: fill (iOS) =====================
    // The fill is drawn as the intersection of the tile's rounded rectangle and a rectangle
    // that grows from the bottom (or left). That way the fill can never poke out of the tile
    // and follows the corner curve at BOTH ends (low and full values), like the iOS sliders.
    Shape {
        id: fillShape
        visible: sTile.isFill
        readonly property real m: dialogRoot.showBorder ? dialogRoot.tileBorderWidth : 0
        x: m
        y: m
        width: sTile.width - m * 2
        height: sTile.height - m * 2
        layer.enabled: true
        layer.samples: 4

        readonly property real r: Math.max(0, Math.min(dialogRoot.cfgRadius - m, width / 2, height / 2))
        property real shownRatio: Math.max(0.0, Math.min(1.0, sTile.currentRatio))
        Behavior on shownRatio {
            NumberAnimation { duration: sliderMouse.pressed ? 40 : 180; easing.type: Easing.OutCubic }
        }
        readonly property real len: shownRatio * (sTile.isHorizontal ? width : height)

        // Outline of the tile's rounded rectangle, cut off at the current fill length.
        // Cutting a convex shape with a straight line is the same as clamping every outline
        // point to that line, so ALL four corners stay rounded at any value (0 - 100 %).
        function buildPoly() {
            const w = width, h = height, rr = r, n = 20
            const horiz = sTile.isHorizontal
            const cut = len
            const corners = [
                { cx: rr,     cy: rr,     a0: Math.PI },          // top-left
                { cx: w - rr, cy: rr,     a0: Math.PI * 1.5 },    // top-right
                { cx: w - rr, cy: h - rr, a0: 0 },                // bottom-right
                { cx: rr,     cy: h - rr, a0: Math.PI * 0.5 }     // bottom-left
            ]
            let pts = []
            for (let c = 0; c < 4; c++) {
                for (let i = 0; i <= n; i++) {
                    const a = corners[c].a0 + (Math.PI / 2) * (i / n)
                    let x = corners[c].cx + rr * Math.cos(a)
                    let y = corners[c].cy + rr * Math.sin(a)
                    if (horiz) x = Math.min(x, cut)        // grows from the left
                        else       y = Math.max(y, h - cut)    // grows from the bottom
                            pts.push(Qt.point(x, y))
                }
            }
            return pts
        }
        readonly property var poly: buildPoly()

        ShapePath {
            fillColor: dialogRoot.activeTileColor
            strokeColor: "transparent"
            strokeWidth: -1
            startX: fillShape.poly.length ? fillShape.poly[0].x : 0
            startY: fillShape.poly.length ? fillShape.poly[0].y : 0
            PathPolyline { path: fillShape.poly }
        }
    }

    Kirigami.Icon {
        visible: sTile.isFill
        source: sTile.iconSource
        width: 20
        height: 20
        anchors.bottom: isHorizontal ? undefined : parent.bottom
        anchors.bottomMargin: isHorizontal ? 0 : 16
        anchors.left: isHorizontal ? parent.left : undefined
        anchors.leftMargin: isHorizontal ? 16 : 0
        anchors.verticalCenter: isHorizontal ? parent.verticalCenter : undefined
        anchors.horizontalCenter: isHorizontal ? undefined : parent.horizontalCenter
        color: sTile.currentRatio > (isHorizontal ? 0.25 : 0.15) ? dialogRoot.activeIconColor : dialogRoot.inactiveIconColor
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    // ===================== STYLES: mac / slim / slimV =====================
    Item {
        id: track
        visible: !sTile.isFill

        readonly property bool mac: sTile.sliderStyle === "mac"
        readonly property bool vert: !sTile.isHorizontal
        readonly property real thick: mac ? 26 : 6
        readonly property real knob: mac ? 26 : 20

        // area the track lives in (tile coordinates)
        x: mac ? 14 : (vert ? Math.round((sTile.width - width) / 2) : 52)
        y: mac ? sTile.height - 14 - height : (vert ? 18 : Math.round((sTile.height - height) / 2))
        width: mac ? sTile.width - 28 : (vert ? knob : sTile.width - 52 - 18)
        height: mac ? knob : (vert ? sTile.height - 18 - 50 : knob)

        property real shownRatio: Math.max(0.0, Math.min(1.0, sTile.currentRatio))
        Behavior on shownRatio {
            NumberAnimation { duration: sliderMouse.pressed ? 40 : 180; easing.type: Easing.OutCubic }
        }
        readonly property real travel: Math.max(0, (vert ? height : width) - knob)
        // fill reaches the knob's far edge (mac) or the knob's centre (slim)
        readonly property real fillLen: (mac ? knob : knob / 2) + travel * shownRatio

        // background track
        Rectangle {
            width: track.vert ? track.thick : track.width
            height: track.vert ? track.height : track.thick
            anchors.centerIn: parent
            radius: track.thick / 2
            color: Qt.rgba(dialogRoot.inactiveIconColor.r, dialogRoot.inactiveIconColor.g, dialogRoot.inactiveIconColor.b, 0.22)
        }

        // fill (always a full pill, so the ends stay rounded at any value)
        Rectangle {
            width: track.vert ? track.thick : track.fillLen
            height: track.vert ? track.fillLen : track.thick
            anchors.left: track.vert ? undefined : parent.left
            anchors.verticalCenter: track.vert ? undefined : parent.verticalCenter
            anchors.bottom: track.vert ? parent.bottom : undefined
            anchors.horizontalCenter: track.vert ? parent.horizontalCenter : undefined
            radius: track.thick / 2
            color: dialogRoot.activeTileColor
        }

        // round knob (slim styles)
        Rectangle {
            visible: !track.mac
            width: track.knob
            height: track.knob
            radius: track.knob / 2
            color: dialogRoot.activeTileColor
            border.color: Qt.rgba(0, 0, 0, 0.12)
            border.width: 1
            x: track.vert ? 0 : track.travel * track.shownRatio
            y: track.vert ? track.travel * (1.0 - track.shownRatio) : 0
        }
    }

    // title + percentage (mac style)
    Item {
        visible: track.mac && !sTile.isFill
        x: 14
        y: 12
        width: sTile.width - 28
        height: 16
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: sTile.titleText
            font.pixelSize: 12
            font.bold: true
            color: dialogRoot.textColor
            elide: Text.ElideRight
            width: parent.width - 40
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(sTile.currentRatio * 100) + "%"
            font.pixelSize: 11
            opacity: 0.7
            color: dialogRoot.textColor
        }
    }

    Kirigami.Icon {
        visible: !sTile.isFill
        source: sTile.iconSource
        width: track.mac ? 16 : 20
        height: width
        x: track.mac ? track.x + track.knob / 2 - width / 2
        : (track.vert ? Math.round((sTile.width - width) / 2) : 18)
        y: track.mac ? track.y + track.knob / 2 - height / 2
        : (track.vert ? sTile.height - 16 - height : Math.round((sTile.height - height) / 2))
        color: track.mac ? dialogRoot.activeIconColor : dialogRoot.textColor
    }

    MouseArea {
        id: sliderMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: dialogRoot.editMode ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
        preventStealing: true
        property real startX: 0
        property real startY: 0

        property bool showTip: false
        Timer {
            id: tipTimer
            interval: 1000
            onTriggered: sliderMouse.showTip = true
        }
        onEntered: tipTimer.start()
        onExited: {
            tipTimer.stop()
            showTip = false
        }

        function updateSlider(mouseX, mouseY) {
            let ratio = 0.0
            if (!sTile.isFill) {
                let t = Math.max(1, track.travel)
                if (isHorizontal) {
                    ratio = (mouseX - track.x - track.knob / 2) / t
                } else {
                    ratio = 1.0 - (mouseY - track.y - track.knob / 2) / t
                }
                ratio = Math.max(0.0, Math.min(1.0, ratio))
            } else if (isHorizontal) {
                ratio = Math.max(0.0, Math.min(1.0, mouseX / width))
            } else {
                ratio = Math.max(0.0, Math.min(1.0, 1.0 - (mouseY / height)))
            }
            if (sTile.clampBottom && ratio < 0.05) ratio = 0.05
                sTile.currentRatio = ratio
                debounceTimer.pendingVal = ratio
                debounceTimer.restart()
        }

        onPressed: (mouse) => {
            tipTimer.stop()
            showTip = false
            if (dialogRoot.editMode) {
                sTile.isDragging = true
                sTile.dragX = sTile.x
                sTile.dragY = sTile.y
                startX = mouse.x
                startY = mouse.y
            } else {
                updateSlider(mouse.x, mouse.y)
            }
        }
        onPositionChanged: (mouse) => {
            if (dialogRoot.editMode && sTile.isDragging) {
                sTile.dragX += mouse.x - startX
                sTile.dragY += mouse.y - startY
            } else if (!dialogRoot.editMode && pressed) {
                updateSlider(mouse.x, mouse.y)
            }
        }
        onReleased: {
            if (dialogRoot.editMode && sTile.isDragging) {
                contentWrapper.handleTileDrop(sTile)
            } else if (!dialogRoot.editMode) {
                sTile.ratioReleased(sTile.currentRatio)
            }
        }

        ToolTip.visible: showTip && !dialogRoot.editMode
        ToolTip.text: sTile.tooltipText + " (" + Math.round(sTile.currentRatio * 100) + "%)"
    }
}
