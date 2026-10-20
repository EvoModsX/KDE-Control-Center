import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    Kirigami.ShadowedRectangle {
        id: sliderFill
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: isHorizontal ? undefined : parent.right
        anchors.top: isHorizontal ? parent.top : undefined
        anchors.margins: dialogRoot.showBorder ? dialogRoot.tileBorderWidth : 0

        width: isHorizontal ? Math.round((parent.width - anchors.margins * 2) * Math.max(0.0, Math.min(1.0, sTile.currentRatio))) : parent.width
        height: isHorizontal ? parent.height : Math.round((parent.height - anchors.margins * 2) * Math.max(0.0, Math.min(1.0, sTile.currentRatio)))

        color: dialogRoot.activeTileColor

        property real innerRadius: Math.max(0, dialogRoot.cfgRadius - anchors.margins)

        corners.bottomLeftRadius: innerRadius
        corners.topLeftRadius: isHorizontal ? innerRadius : ((height >= parent.height - 8) ? innerRadius : 5)
        corners.bottomRightRadius: isHorizontal ? ((width >= parent.width - 8) ? innerRadius : 5) : innerRadius
        corners.topRightRadius: isHorizontal ? ((width >= parent.width - 8) ? innerRadius : 5) : ((height >= parent.height - 8) ? innerRadius : 5)

        Behavior on height {
            enabled: !isHorizontal
            NumberAnimation {
                duration: sliderMouse.pressed ? 40 : 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            enabled: isHorizontal
            NumberAnimation {
                duration: sliderMouse.pressed ? 40 : 180
                easing.type: Easing.OutCubic
            }
        }
    }

    Kirigami.Icon {
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
            if (isHorizontal) {
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
