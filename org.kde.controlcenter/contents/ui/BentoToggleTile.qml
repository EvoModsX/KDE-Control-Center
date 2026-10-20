import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: dTile
    property var dialogRoot
    property var contentWrapper
    property var blurHelper

    property string tileKey: ""
    property string tileName: ""
    property string subtitleText: ""
    property bool inDrawer: true
    property int drawerCol: 0
    property int drawerRow: 0
    property int gridCol: 0
    property int gridRow: 0
    property int spanCols: 1
    property int spanRows: 1
    property bool activeState: false
    property string iconSource: ""
    signal tileClicked()

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
        enabled: !dTile.isDragging && dialogRoot.visible
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
    }
    Behavior on y {
        enabled: !dTile.isDragging && dialogRoot.visible
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
    }
    Behavior on width {
        enabled: !dTile.isDragging && dialogRoot.visible
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
    }
    Behavior on height {
        enabled: !dTile.isDragging && dialogRoot.visible
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
    }

    radius: dialogRoot.cfgRadius
    color: (isFullFill && activeState) ? dialogRoot.activeTileColor : dialogRoot.tileBaseColor
    border.color: dialogRoot.editMode ? Qt.rgba(1, 1, 1, 0.35) : dialogRoot.tileBorderColor
    border.width: dialogRoot.tileBorderWidth
    clip: false

    Behavior on color { ColorAnimation { duration: 150 } }

    property real hoverScale: tileMouse.containsMouse ? 1.03 : 1.0
    Behavior on hoverScale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    scale: (dialogRoot.animStyle === 2 ? 1.0 : (isDragging ? 1.03 : 1.0) * animProgress) * hoverScale
    transformOrigin: dialogRoot.isBottomLeft ? Item.BottomLeft : Item.BottomRight
    onScaleChanged: { if(blurHelper) blurHelper.update() }
    onXChanged: { if(blurHelper) blurHelper.update() }
    onYChanged: { if(blurHelper) blurHelper.update() }
    onWidthChanged: { if(blurHelper) blurHelper.update() }
    onHeightChanged: { if(blurHelper) blurHelper.update() }

    readonly property real deltaX: dialogRoot.isBottomLeft ? -targetX : (contentWrapper.width - (targetX + targetW))
    readonly property real deltaY: contentWrapper.height - (targetY + targetH)

    transform: Translate {
        x: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - dTile.animProgress) * dTile.deltaX
        y: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - dTile.animProgress) * dTile.deltaY
    }

    property real baseOpacity: 0.0
    property real animProgress: 0.0
    property int animDelay: 0
    property alias enterAnim: dtEnter
    property alias dismissAnim: dtDismiss

    opacity: inDrawer ? (baseOpacity * contentWrapper.drawerAnimProgress) : baseOpacity

    SequentialAnimation {
        id: dtEnter
        PauseAnimation { duration: dTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: dTile
                property: "baseOpacity"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 380) / dialogRoot.speedMultiplier)
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: dTile
                property: "animProgress"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 620) / dialogRoot.speedMultiplier)
                easing.type: dialogRoot.animStyle === 0 ? Easing.OutBack : Easing.OutCubic
                easing.overshoot: dialogRoot.animStyle === 0 ? 1.004 : 1.0
            }
        }
    }
    SequentialAnimation {
        id: dtDismiss
        PauseAnimation { duration: dTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: dTile
                property: "animProgress"
                to: 0.0
                duration: Math.round(160 / dialogRoot.speedMultiplier)
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: dTile
                property: "baseOpacity"
                to: 0.0
                duration: Math.round(130 / dialogRoot.speedMultiplier)
                easing.type: Easing.InQuad
            }
        }
    }
    function triggerAnim(entering, delay) {
        animDelay = delay
        dtEnter.stop()
        dtDismiss.stop()
        if (entering) {
            baseOpacity = 0.0
            animProgress = 0.0
            dtEnter.start()
        } else {
            dtDismiss.start()
        }
    }

    shadow {
        size: dialogRoot.showShadow ? (dTile.isDragging ? dialogRoot.computedShadowSize + 12 : dialogRoot.computedShadowSize) : 0
        color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
        xOffset: 0
        yOffset: 0
    }

    Item {
        anchors.fill: parent

        property real expansionProgress: Math.max(0.0, Math.min(1.0, (dTile.width - contentWrapper.cellW) / contentWrapper.cellW))

        // Icon Container Pill
        Rectangle {
            id: iconCircle
            width: is2x2 ? 48 : 44
            height: width
            radius: width / 2

            x: is2x2 ? 16 : (((dTile.width - 44) / 2) * (1.0 - parent.expansionProgress) + (12) * parent.expansionProgress)
            y: is2x2 ? 16 : ((dTile.height - height) / 2)

            color: isFullFill ? "transparent" : (dTile.activeState ? dialogRoot.activeTileColor : Qt.rgba(1, 1, 1, 0.12))
            Behavior on color { ColorAnimation { duration: 150 } }

            Kirigami.Icon {
                anchors.centerIn: parent
                source: dTile.iconSource
                width: Math.round((is2x2 ? 28 : 24) * dialogRoot.iconScale)
                height: width
                color: isFullFill ? (dTile.activeState ? dialogRoot.activeIconColor : dialogRoot.textColor) : (dTile.activeState ? dialogRoot.activeIconColor : dialogRoot.inactiveIconColor)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        // Horizontal Layout (1x1 & 2x1)
        ColumnLayout {
            anchors.left: iconCircle.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            visible: !is2x2
            opacity: parent.expansionProgress

            Item {
                Layout.fillWidth: true
                height: titleLabel.implicitHeight
                clip: true

                PlasmaComponents.Label {
                    id: titleLabel
                    text: dTile.tileName
                    font.pixelSize: 13
                    font.bold: true
                    color: isFullFill && dTile.activeState ? dialogRoot.activeIconColor : dialogRoot.textColor
                    width: Math.max(implicitWidth, parent.width)

                    SequentialAnimation on x {
                        running: titleLabel.implicitWidth > titleLabel.parent.width && dTile.spanCols === 2 && !is2x2 && !dialogRoot.editMode
                        loops: Animation.Infinite
                        PauseAnimation { duration: 2000 }
                        NumberAnimation {
                            from: 0
                            to: titleLabel.parent.width - titleLabel.implicitWidth
                            duration: Math.max(1, titleLabel.implicitWidth - titleLabel.parent.width) * 40
                        }
                        PauseAnimation { duration: 2000 }
                        NumberAnimation { to: 0; duration: Math.max(1, titleLabel.implicitWidth - titleLabel.parent.width) * 40 }
                    }
                }
            }

            PlasmaComponents.Label {
                text: dTile.subtitleText
                font.pixelSize: 11
                opacity: isFullFill && dTile.activeState ? 0.8 : 0.65
                color: isFullFill && dTile.activeState ? dialogRoot.activeIconColor : dialogRoot.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }
        }

        // Vertical Bottom-Left Stacked Layout (2x2)
        ColumnLayout {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            spacing: 2

            visible: is2x2

            PlasmaComponents.Label {
                text: dTile.tileName
                font.pixelSize: 14
                font.bold: true
                color: isFullFill && dTile.activeState ? dialogRoot.activeIconColor : dialogRoot.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                text: dTile.subtitleText
                font.pixelSize: 12
                opacity: isFullFill && dTile.activeState ? 0.8 : 0.65
                color: isFullFill && dTile.activeState ? dialogRoot.activeIconColor : dialogRoot.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: dialogRoot.editMode ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
        property real startX: 0
        property real startY: 0

        property bool showTip: false
        Timer {
            id: tipTimer1
            interval: 1000
            onTriggered: tileMouse.showTip = true
        }
        onEntered: tipTimer1.start()
        onExited: {
            tipTimer1.stop()
            showTip = false
        }

        onPressed: (mouse) => {
            tipTimer1.stop()
            showTip = false
            if (dialogRoot.editMode) {
                dTile.isDragging = true
                dTile.dragX = dTile.x
                dTile.dragY = dTile.y
                startX = mouse.x
                startY = mouse.y
            }
        }
        onPositionChanged: (mouse) => {
            if (dialogRoot.editMode && dTile.isDragging) {
                dTile.dragX += mouse.x - startX
                dTile.dragY += mouse.y - startY
            }
        }
        onReleased: {
            if (dialogRoot.editMode && dTile.isDragging) contentWrapper.handleTileDrop(dTile)
        }
        onClicked: {
            if (!dialogRoot.editMode) dTile.tileClicked()
        }

        ToolTip.visible: showTip && !dialogRoot.editMode
        ToolTip.text: dTile.tileName
    }

    MouseArea {
        id: resizeHandle
        width: 24
        height: 24
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        z: 10
        enabled: dialogRoot.editMode && !dTile.inDrawer
        visible: dialogRoot.editMode && !dTile.inDrawer
        cursorShape: Qt.SizeFDiagCursor

        Rectangle {
            width: 10
            height: 10
            radius: 5
            color: dialogRoot.inactiveIconColor
            opacity: 0.6
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 7
        }

        property real startAbsX: 0
        property real startAbsY: 0

        onPressed: (mouse) => {
            let p = resizeHandle.mapToItem(contentWrapper, mouse.x, mouse.y)
            startAbsX = p.x
            startAbsY = p.y
            mouse.accepted = true
        }
        onPositionChanged: (mouse) => {
            let p = resizeHandle.mapToItem(contentWrapper, mouse.x, mouse.y)
            let deltaX = p.x - startAbsX
            let deltaY = p.y - startAbsY
            let threshold = contentWrapper.cellW * 0.45

            if (deltaX > threshold && dTile.spanCols === 1) {
                if (dTile.gridCol + 2 <= 4) {
                    dTile.spanCols = 2
                    dTile.spanRows = 1
                    contentWrapper.resolveCollisions(dTile)
                    contentWrapper.applyGravity()
                    dialogRoot.saveTileLayout()
                    startAbsX = p.x
                    startAbsY = p.y
                }
            } else if (deltaY > threshold && dTile.spanCols === 2 && dTile.spanRows === 1) {
                dTile.spanCols = 2
                dTile.spanRows = 2
                contentWrapper.resolveCollisions(dTile)
                contentWrapper.applyGravity()
                dialogRoot.saveTileLayout()
                startAbsX = p.x
                startAbsY = p.y
            } else if (deltaY < -threshold && dTile.is2x2) {
                dTile.spanCols = 2
                dTile.spanRows = 1
                contentWrapper.applyGravity()
                dialogRoot.saveTileLayout()
                startAbsX = p.x
                startAbsY = p.y
            } else if (deltaX < -threshold && dTile.spanCols === 2 && dTile.spanRows === 1) {
                dTile.spanCols = 1
                dTile.spanRows = 1
                contentWrapper.applyGravity()
                dialogRoot.saveTileLayout()
                startAbsX = p.x
                startAbsY = p.y
            }
        }
    }
}
