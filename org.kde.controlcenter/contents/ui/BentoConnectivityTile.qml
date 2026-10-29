import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Kirigami.ShadowedRectangle {
    id: connTile
    property var dialogRoot
    property var contentWrapper
    property var blurHelper

    property string tileKey: "connectivity"
    property string tileName: "Connectivity"
    property string subtitleText: ""
    property bool inDrawer: true
    property int drawerCol: 0
    property int drawerRow: 0
    property int gridCol: 0
    property int gridRow: 0
    property int spanCols: 2
    property int spanRows: 2
    property bool activeState: false
    property string iconSource: ""
    signal tileClicked()
    signal disconnectRequested()
    signal settingsRequested()

    readonly property bool is2x2: spanCols === 2 && spanRows === 2
    readonly property bool isFullFill: dialogRoot.tileFillMode === 1

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
        enabled: !connTile.isDragging && dialogRoot.visible
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
    }
    Behavior on y {
        enabled: !connTile.isDragging && dialogRoot.visible
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
    }
    Behavior on width {
        enabled: !connTile.isDragging && dialogRoot.visible
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
    }
    Behavior on height {
        enabled: !connTile.isDragging && dialogRoot.visible
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
    }

    radius: dialogRoot.cfgRadius
    color: dialogRoot.tileBaseColor
    border.color: dialogRoot.editMode ? Qt.rgba(1, 1, 1, 0.35) : dialogRoot.tileBorderColor
    border.width: dialogRoot.tileBorderWidth
    clip: true

    scale: (dialogRoot.animStyle === 2 ? 1.0 : (isDragging ? 1.03 : 1.0) * animProgress)
    transformOrigin: dialogRoot.isBottomLeft ? Item.BottomLeft : Item.BottomRight
    onScaleChanged: { if(blurHelper) blurHelper.update() }
    onXChanged: { if(blurHelper) blurHelper.update() }
    onYChanged: { if(blurHelper) blurHelper.update() }
    onWidthChanged: { if(blurHelper) blurHelper.update() }
    onHeightChanged: { if(blurHelper) blurHelper.update() }

    readonly property real deltaX: dialogRoot.isBottomLeft ? -targetX : (contentWrapper.width - (targetX + targetW))
    readonly property real deltaY: contentWrapper.height - (targetY + targetH)

    transform: Translate {
        x: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - connTile.animProgress) * connTile.deltaX
        y: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - connTile.animProgress) * connTile.deltaY
    }

    property real baseOpacity: 0.0
    property real animProgress: 0.0
    property int animDelay: 0
    property alias enterAnim: connEnter
    property alias dismissAnim: connDismiss

    opacity: inDrawer ? (baseOpacity * contentWrapper.drawerAnimProgress) : baseOpacity

    SequentialAnimation {
        id: connEnter
        PauseAnimation { duration: connTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: connTile
                property: "baseOpacity"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 380) / dialogRoot.speedMultiplier)
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: connTile
                property: "animProgress"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 620) / dialogRoot.speedMultiplier)
                easing.type: dialogRoot.animStyle === 0 ? Easing.OutBack : Easing.OutCubic
                easing.overshoot: dialogRoot.animStyle === 0 ? 1.004 : 1.0
            }
        }
    }
    SequentialAnimation {
        id: connDismiss
        PauseAnimation { duration: connTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: connTile
                property: "animProgress"
                to: 0.0
                duration: Math.round(160 / dialogRoot.speedMultiplier)
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: connTile
                property: "baseOpacity"
                to: 0.0
                duration: Math.round(130 / dialogRoot.speedMultiplier)
                easing.type: Easing.InQuad
            }
        }
    }
    function triggerAnim(entering, delay) {
        animDelay = delay
        connEnter.stop()
        connDismiss.stop()
        if (entering) {
            baseOpacity = 0.0
            animProgress = 0.0
            connEnter.start()
        } else {
            connDismiss.start()
        }
    }

    shadow {
        size: dialogRoot.showShadow ? (connTile.isDragging ? dialogRoot.computedShadowSize + 12 : dialogRoot.computedShadowSize) : 0
        color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
        xOffset: 0
        yOffset: 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 15
        anchors.bottomMargin: 8
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 4

        // Top Wi-Fi Row
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                id: wifiCircle
                width: 48
                height: 48
                radius: 24
                color: dialogRoot.wifiStatus ? dialogRoot.activeTileColor : Qt.rgba(1, 1, 1, 0.12)
                Behavior on color { ColorAnimation { duration: 150 } }

                property real hoverScale: wifiMouse.containsMouse ? 1.06 : 1.0
                Behavior on hoverScale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                scale: hoverScale
                transformOrigin: Item.Center

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "network-wireless-symbolic"
                    width: Math.round(28 * dialogRoot.iconScale)
                    height: width
                    color: dialogRoot.wifiStatus ? dialogRoot.activeIconColor : dialogRoot.textColor
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: wifiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: dialogRoot.editMode ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (!dialogRoot.editMode) dialogRoot.toggleWifi()
                    }
                    onWheel: (wheel) => {
                        if (!dialogRoot.editMode && wheel.angleDelta.y < 0) dialogRoot.activeSubView = "wifi"
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                PlasmaComponents.Label {
                    text: dialogRoot.wifiStatus && dialogRoot.wifiSsid !== "" ? dialogRoot.wifiSsid : "Wi-Fi"
                    font.pixelSize: 13
                    font.bold: true
                    color: dialogRoot.textColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                PlasmaComponents.Label {
                    text: dialogRoot.wifiStatus ? "Connected" : "Off"
                    font.pixelSize: 11
                    color: dialogRoot.textColor
                    opacity: 0.65
                }
            }
        }

        // Thin Center Divider Line (Moved lower)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 10
            Layout.bottomMargin: 4
            color: Qt.rgba(1, 1, 1, 0.12)
        }

        // Bottom Row: Bluetooth & DND
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: btCircle
                    width: 48
                    height: 48
                    radius: 24
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: dialogRoot.btStatus ? dialogRoot.activeTileColor : Qt.rgba(1, 1, 1, 0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    property real hoverScale: btMouse.containsMouse ? 1.06 : 1.0
                    Behavior on hoverScale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    scale: hoverScale
                    transformOrigin: Item.Center

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "preferences-system-bluetooth"
                        width: Math.round(28 * dialogRoot.iconScale)
                        height: width
                        color: dialogRoot.btStatus ? dialogRoot.activeIconColor : dialogRoot.textColor
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: btMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: dialogRoot.editMode ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: {
                            if (!dialogRoot.editMode) dialogRoot.toggleBluetooth()
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: dndCircle
                    width: 48
                    height: 48
                    radius: 24
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: dialogRoot.dndStatus ? dialogRoot.activeTileColor : Qt.rgba(1, 1, 1, 0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    property real hoverScale: dndMouse.containsMouse ? 1.06 : 1.0
                    Behavior on hoverScale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    scale: hoverScale
                    transformOrigin: Item.Center

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "notifications-disabled"
                        width: Math.round(28 * dialogRoot.iconScale)
                        height: width
                        color: dialogRoot.dndStatus ? dialogRoot.activeIconColor : dialogRoot.textColor
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: dndMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: dialogRoot.editMode ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: {
                            if (!dialogRoot.editMode) dialogRoot.toggleDnd()
                        }
                    }
                }
            }
        }
    }

    // Edit mode drag controller (only active during edit mode)
    MouseArea {
        id: connMouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        enabled: dialogRoot.editMode
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        property real startX: 0
        property real startY: 0

        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                connTile.isDragging = true
                connTile.dragX = connTile.x
                connTile.dragY = connTile.y
                startX = mouse.x
                startY = mouse.y
            }
        }
        onPositionChanged: (mouse) => {
            if (connTile.isDragging) {
                connTile.dragX += mouse.x - startX
                connTile.dragY += mouse.y - startY
            }
        }
        onReleased: {
            if (connTile.isDragging) contentWrapper.handleTileDrop(connTile)
        }
    }
}
