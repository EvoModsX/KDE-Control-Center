import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: batTile
    property var dialogRoot
    property var contentWrapper
    property var blurHelper

    property bool inDrawer: false
    height: 38
    implicitWidth: batteryLayout.implicitWidth + 24
    radius: 19
    color: dialogRoot.tileBaseColor
    border.color: dialogRoot.tileBorderColor
    border.width: dialogRoot.tileBorderWidth
    clip: false

    property real hoverScale: batMouse.containsMouse ? 1.03 : 1.0
    Behavior on hoverScale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    scale: (dialogRoot.animStyle === 2 ? 1.0 : animProgress) * hoverScale
    transformOrigin: dialogRoot.isBottomLeft ? Item.BottomLeft : Item.BottomRight
    onScaleChanged: { if(blurHelper) blurHelper.update() }

    readonly property real deltaX: !parent ? 0 : dialogRoot.isBottomLeft ? -parent.mapToItem(contentWrapper, x, y).x : (contentWrapper.width - (parent.mapToItem(contentWrapper, x, y).x + width))
    readonly property real deltaY: !parent ? 0 : contentWrapper.height - (parent.mapToItem(contentWrapper, x, y).y + height)

    transform: Translate {
        x: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - batTile.animProgress) * batTile.deltaX
        y: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - batTile.animProgress) * batTile.deltaY
    }

    property real baseOpacity: 0.0
    property real animProgress: 0.0
    property int animDelay: 0
    property alias enterAnim: batEnter
    property alias dismissAnim: batDismiss

    opacity: inDrawer ? (baseOpacity * contentWrapper.drawerAnimProgress) : baseOpacity

    SequentialAnimation {
        id: batEnter
        PauseAnimation { duration: batTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: batTile
                property: "baseOpacity"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 380) / dialogRoot.speedMultiplier)
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: batTile
                property: "animProgress"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 620) / dialogRoot.speedMultiplier)
                easing.type: dialogRoot.animStyle === 0 ? Easing.OutBack : Easing.OutCubic
                easing.overshoot: dialogRoot.animStyle === 0 ? 1.004 : 1.0
            }
        }
    }
    SequentialAnimation {
        id: batDismiss
        PauseAnimation { duration: batTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: batTile
                property: "animProgress"
                to: 0.0
                duration: Math.round(160 / dialogRoot.speedMultiplier)
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: batTile
                property: "baseOpacity"
                to: 0.0
                duration: Math.round(130 / dialogRoot.speedMultiplier)
                easing.type: Easing.InQuad
            }
        }
    }
    function triggerAnim(entering, delay) {
        animDelay = delay
        batEnter.stop()
        batDismiss.stop()
        if (entering) {
            baseOpacity = 0.0
            animProgress = 0.0
            batEnter.start()
        } else {
            batDismiss.start()
        }
    }

    shadow {
        size: dialogRoot.showShadow ? dialogRoot.computedShadowSize : 0
        color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
        xOffset: 0
        yOffset: 0
    }

    RowLayout {
        id: batteryLayout
        anchors.centerIn: parent
        spacing: 6
        Kirigami.Icon {
            width: 16
            height: 16
            source: dialogRoot.batteryCharging ? "battery-charging" : "battery-080"
            color: dialogRoot.inactiveIconColor
        }
        PlasmaComponents.Label {
            text: dialogRoot.batteryPercent + "%"
            font.pixelSize: 12
            font.bold: true
            color: dialogRoot.textColor
        }
    }

    MouseArea {
        id: batMouse
        anchors.fill: parent
        hoverEnabled: true

        property bool showTip: false
        Timer {
            id: btTmr
            interval: 1000
            onTriggered: batMouse.showTip = true
        }
        onEntered: btTmr.start()
        onExited: {
            btTmr.stop()
            showTip = false
        }
        onPressed: (mouse) => {
            btTmr.stop()
            showTip = false
        }

        ToolTip.visible: showTip && !dialogRoot.editMode
        ToolTip.text: dialogRoot.batteryCharging ? "Charging" : "Discharging"
    }
}
