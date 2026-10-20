import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: hTile
    property var dialogRoot
    property var contentWrapper
    property var blurHelper

    property string iconSource: ""
    property string tooltipText: ""
    property bool isEditButton: false
    property bool inDrawer: false

    signal clicked()

    width: isEditButton ? 32 : 38
    height: isEditButton ? 32 : 38
    radius: width / 2
    color: (isEditButton && dialogRoot.editMode) ? dialogRoot.activeTileColor : dialogRoot.tileBaseColor
    border.color: dialogRoot.tileBorderColor
    border.width: dialogRoot.tileBorderWidth
    clip: false
    Behavior on color { ColorAnimation { duration: 150 } }

    property real hoverScale: hMouse.containsMouse ? 1.05 : 1.0
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
        x: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - hTile.animProgress) * hTile.deltaX
        y: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - hTile.animProgress) * hTile.deltaY
    }

    property real baseOpacity: 0.0
    property real animProgress: 0.0
    property int animDelay: 0
    property alias enterAnim: hEnter
    property alias dismissAnim: hDismiss

    opacity: inDrawer ? (baseOpacity * contentWrapper.drawerAnimProgress) : baseOpacity

    SequentialAnimation {
        id: hEnter
        PauseAnimation { duration: hTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: hTile
                property: "baseOpacity"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 380) / dialogRoot.speedMultiplier)
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: hTile
                property: "animProgress"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 620) / dialogRoot.speedMultiplier)
                easing.type: dialogRoot.animStyle === 0 ? Easing.OutBack : Easing.OutCubic
                easing.overshoot: dialogRoot.animStyle === 0 ? 1.004 : 1.0
            }
        }
    }
    SequentialAnimation {
        id: hDismiss
        PauseAnimation { duration: hTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: hTile
                property: "animProgress"
                to: 0.0
                duration: Math.round(160 / dialogRoot.speedMultiplier)
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: hTile
                property: "baseOpacity"
                to: 0.0
                duration: Math.round(130 / dialogRoot.speedMultiplier)
                easing.type: Easing.InQuad
            }
        }
    }
    function triggerAnim(entering, delay) {
        animDelay = delay
        hEnter.stop()
        hDismiss.stop()
        if (entering) {
            baseOpacity = 0.0
            animProgress = 0.0
            hEnter.start()
        } else {
            hDismiss.start()
        }
    }

    shadow {
        size: dialogRoot.showShadow ? dialogRoot.computedShadowSize : 0
        color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
        xOffset: 0
        yOffset: 0
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: isEditButton ? 15 : 18
        height: isEditButton ? 15 : 18
        source: hTile.iconSource
        color: (hTile.isEditButton && dialogRoot.editMode) ? dialogRoot.activeIconColor : dialogRoot.inactiveIconColor
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: hMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        property bool showTip: false
        Timer {
            id: hTmr
            interval: 1000
            onTriggered: hMouse.showTip = true
        }
        onEntered: hTmr.start()
        onExited: {
            hTmr.stop()
            showTip = false
        }
        onPressed: (mouse) => {
            hTmr.stop()
            showTip = false
            hTile.clicked()
        }

        ToolTip.visible: showTip && (!dialogRoot.editMode || hTile.isEditButton)
        ToolTip.text: hTile.tooltipText
    }
}
