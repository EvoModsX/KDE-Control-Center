import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: mediaTile
    property var dialogRoot
    property var contentWrapper
    property var blurHelper

    property string tileKey: "media"
    property bool inDrawer: false
    property int drawerCol: 0
    property int drawerRow: 0
    property int gridCol: 0
    property int gridRow: 1
    property int spanCols: 2
    property int spanRows: 2

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
        enabled: !mediaTile.isDragging && dialogRoot.visible
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutBack
            easing.overshoot: 1.02
        }
    }
    Behavior on y {
        enabled: !mediaTile.isDragging && dialogRoot.visible
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutBack
            easing.overshoot: 1.02
        }
    }
    Behavior on width {
        enabled: !mediaTile.isDragging && dialogRoot.visible
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

    property real hoverScale: mediaHoverArea.containsMouse ? 1.015 : 1.0
    Behavior on hoverScale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    scale: (dialogRoot.animStyle === 2 ? 1.0 : (isDragging ? 1.02 : 1.0) * animProgress) * hoverScale
    transformOrigin: dialogRoot.isBottomLeft ? Item.BottomLeft : Item.BottomRight
    onScaleChanged: { if(blurHelper) blurHelper.update() }
    onXChanged: { if(blurHelper) blurHelper.update() }
    onYChanged: { if(blurHelper) blurHelper.update() }
    onWidthChanged: { if(blurHelper) blurHelper.update() }

    readonly property real deltaX: dialogRoot.isBottomLeft ? -targetX : (contentWrapper.width - (targetX + targetW))
    readonly property real deltaY: contentWrapper.height - (targetY + targetH)

    transform: Translate {
        x: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - mediaTile.animProgress) * mediaTile.deltaX
        y: dialogRoot.animStyle === 2 ? 0 : Math.max(0.0, 1.0 - mediaTile.animProgress) * mediaTile.deltaY
    }

    property real baseOpacity: 0.0
    property real animProgress: 0.0
    property int animDelay: 0
    property alias enterAnim: medEnter
    property alias dismissAnim: medDismiss

    opacity: inDrawer ? (baseOpacity * contentWrapper.drawerAnimProgress) : baseOpacity

    SequentialAnimation {
        id: medEnter
        PauseAnimation { duration: mediaTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: mediaTile
                property: "baseOpacity"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 380) / dialogRoot.speedMultiplier)
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: mediaTile
                property: "animProgress"
                to: 1.0
                duration: Math.round((dialogRoot.animStyle === 2 ? 220 : 620) / dialogRoot.speedMultiplier)
                easing.type: dialogRoot.animStyle === 0 ? Easing.OutBack : Easing.OutCubic
                easing.overshoot: dialogRoot.animStyle === 0 ? 1.002 : 1.0
            }
        }
    }
    SequentialAnimation {
        id: medDismiss
        PauseAnimation { duration: mediaTile.animDelay }
        ParallelAnimation {
            NumberAnimation {
                target: mediaTile
                property: "animProgress"
                to: 0.0
                duration: Math.round(160 / dialogRoot.speedMultiplier)
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: mediaTile
                property: "baseOpacity"
                to: 0.0
                duration: Math.round(130 / dialogRoot.speedMultiplier)
                easing.type: Easing.InQuad
            }
        }
    }
    function triggerAnim(entering, delay) {
        animDelay = delay
        medEnter.stop()
        medDismiss.stop()
        if (entering) {
            baseOpacity = 0.0
            animProgress = 0.0
            medEnter.start()
        } else {
            medDismiss.start()
        }
    }

    shadow {
        size: dialogRoot.showShadow ? (mediaTile.isDragging ? dialogRoot.computedShadowSize + 12 : dialogRoot.computedShadowSize) : 0
        color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
        xOffset: 0
        yOffset: 0
    }

    function formatTime(s) {
        if (isNaN(s) || s <= 0) return "0:00"
            let mins = Math.floor(s / 60)
            let secs = Math.floor(s % 60)
            return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    property real exp: Math.max(0.0, Math.min(1.0, (width - contentWrapper.getGridW(2)) / Math.max(1, contentWrapper.getGridW(4) - contentWrapper.getGridW(2))))

    Item {
        anchors.fill: parent

        Kirigami.ShadowedImage {
            id: albumArtContainer
            x: 18 - (2 * mediaTile.exp)
            y: 18 - (2 * mediaTile.exp)
            width: 44 + (mediaTile.height - 32 - 44) * mediaTile.exp
            height: width
            radius: 12 + 8 * mediaTile.exp
            color: Qt.rgba(1, 1, 1, 0.08)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            source: {
                let art = dialogRoot.mediaArtUrl || ""
                if (art === "") return ""
                    if (art.startsWith("/")) return "file://" + art
                        return art
            }
            fillMode: Image.PreserveAspectCrop

            Kirigami.Icon {
                anchors.centerIn: parent
                width: parent.width * 0.5
                height: parent.height * 0.5
                source: "media-default-album"
                color: dialogRoot.inactiveIconColor
                opacity: 0.45
                visible: albumArtContainer.status !== Image.Ready || albumArtContainer.source == ""
            }
        }

        Kirigami.Icon {
            source: "video-display"
            color: dialogRoot.inactiveIconColor
            width: 16
            height: 16
            x: mediaTile.width - 18 - 16
            y: 18
            opacity: 0.8 * (1.0 - mediaTile.exp)
            visible: opacity > 0
        }

        Rectangle {
            width: 30
            height: 30
            radius: 15
            color: Qt.rgba(1, 1, 1, 0.12)
            x: mediaTile.width - 18 - 30
            y: 16
            opacity: mediaTile.exp
            visible: opacity > 0
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: "media-cast"
                color: dialogRoot.inactiveIconColor
            }
        }

        ColumnLayout {
            x: 18 + (albumArtContainer.width + 12) * mediaTile.exp
            y: (albumArtContainer.y + albumArtContainer.height + 8) * (1.0 - mediaTile.exp) + 16 * mediaTile.exp
            width: Math.max(10, mediaTile.width - x - 18 - (40 * mediaTile.exp))
            spacing: 2

            Item {
                Layout.fillWidth: true
                height: titleLabel.implicitHeight
                clip: true

                PlasmaComponents.Label {
                    id: titleLabel
                    text: dialogRoot.mediaTitle
                    font.pixelSize: 13 + (2 * mediaTile.exp)
                    font.bold: true
                    color: dialogRoot.textColor
                    width: Math.max(implicitWidth, parent.width)

                    SequentialAnimation on x {
                        id: scrollAnim
                        running: titleLabel.implicitWidth > titleLabel.parent.width && mediaTile.spanCols === 4 && !dialogRoot.editMode
                        loops: Animation.Infinite

                        onRunningChanged: {
                            if (!running) {
                                titleLabel.x = 0
                            }
                        }

                        PauseAnimation {
                            duration: 2000
                        }
                        NumberAnimation {
                            from: 0
                            to: titleLabel.parent.width - titleLabel.implicitWidth
                            duration: Math.max(1, titleLabel.implicitWidth - titleLabel.parent.width) * 40
                        }
                        PauseAnimation {
                            duration: 2000
                        }
                        NumberAnimation {
                            to: 0
                            duration: Math.max(1, titleLabel.implicitWidth - titleLabel.parent.width) * 40
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                text: dialogRoot.mediaArtist
                font.pixelSize: 10 + (2 * mediaTile.exp)
                opacity: 0.65
                color: dialogRoot.textColor
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }
        }

        RowLayout {
            id: controlsRow
            spacing: 12 + 16 * mediaTile.exp

            x: (mediaTile.width - width) / 2 * (1.0 - mediaTile.exp) + (albumArtContainer.x + albumArtContainer.width + 12 + (mediaTile.width - (albumArtContainer.x + albumArtContainer.width + 12) - 18 - width) / 2) * mediaTile.exp
            y: (mediaTile.height - 20 - height) * (1.0 - mediaTile.exp) + (mediaTile.height - 56 - height) * mediaTile.exp

            MouseArea {
                width: 26 + 6 * mediaTile.exp
                height: width
                cursorShape: Qt.PointingHandCursor
                enabled: !dialogRoot.editMode
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 18 + 4 * mediaTile.exp
                    height: width
                    source: "media-skip-backward"
                    color: dialogRoot.inactiveIconColor
                    opacity: 0.85
                }
                onClicked: dialogRoot.runCommand("playerctl previous")
            }

            MouseArea {
                width: 30 + 10 * mediaTile.exp
                height: width
                cursorShape: Qt.PointingHandCursor
                enabled: !dialogRoot.editMode
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 22 + 6 * mediaTile.exp
                    height: width
                    source: dialogRoot.mediaStatus === "Playing" ? "media-playback-pause" : "media-playback-start"
                    color: dialogRoot.inactiveIconColor
                }
                onClicked: dialogRoot.runCommand("playerctl play-pause")
            }

            MouseArea {
                width: 26 + 6 * mediaTile.exp
                height: width
                cursorShape: Qt.PointingHandCursor
                enabled: !dialogRoot.editMode
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 18 + 4 * mediaTile.exp
                    height: width
                    source: "media-skip-forward"
                    color: dialogRoot.inactiveIconColor
                    opacity: 0.85
                }
                onClicked: dialogRoot.runCommand("playerctl next")
            }
        }

        Item {
            x: albumArtContainer.x + albumArtContainer.width + 18
            y: mediaTile.height - 36
            width: mediaTile.width - x - 18
            height: 12
            opacity: mediaTile.exp
            visible: opacity > 0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.2)

                Rectangle {
                    width: dialogRoot.mediaLength > 0 ? parent.width * (dialogRoot.mediaPosition / dialogRoot.mediaLength) : 0
                    height: parent.height
                    radius: 2
                    color: dialogRoot.activeTileColor
                    Behavior on width {
                        NumberAnimation {
                            duration: 1000
                            easing.type: Easing.Linear
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -12
                    cursorShape: Qt.PointingHandCursor
                    enabled: !dialogRoot.editMode
                    onClicked: (mouse) => {
                        if (dialogRoot.mediaLength > 0) {
                            let rectX = Math.max(0, Math.min(mouse.x - 12, parent.width))
                            let newPos = (rectX / parent.width) * dialogRoot.mediaLength
                            dialogRoot.runCommand("playerctl position " + newPos)
                            dialogRoot.mediaPosition = newPos
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                anchors.left: parent.left
                anchors.top: parent.bottom
                anchors.topMargin: 6
                text: formatTime(dialogRoot.mediaPosition)
                font.pixelSize: 10
                color: dialogRoot.textColor
                opacity: 0.7
            }
            PlasmaComponents.Label {
                anchors.right: parent.right
                anchors.top: parent.bottom
                anchors.topMargin: 6
                text: "-" + formatTime(dialogRoot.mediaLength - dialogRoot.mediaPosition)
                font.pixelSize: 10
                color: dialogRoot.textColor
                opacity: 0.7
            }
        }
    }

    MouseArea {
        id: mediaHoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property bool showTip: false
        Timer {
            id: medTimer1
            interval: 1000
            onTriggered: mediaHoverArea.showTip = true
        }
        onEntered: medTimer1.start()
        onExited: {
            medTimer1.stop()
            showTip = false
        }

        onClicked: (mouse) => {
            if (dialogRoot.editMode) return;
            // Open the Media Sub-View on click
            dialogRoot.activeSubView = "media"
            if (blurHelper) blurHelper.update()
        }

        ToolTip.visible: showTip && !dialogRoot.editMode
        ToolTip.text: "Click to open Now Playing"
    }

    MouseArea {
        id: masterDragArea
        anchors.fill: parent
        z: 8
        enabled: dialogRoot.editMode
        visible: dialogRoot.editMode
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true

        property real startX: 0
        property real startY: 0

        onPressed: (mouse) => {
            mediaHoverArea.showTip = false
            mediaTile.isDragging = true
            mediaTile.dragX = mediaTile.x
            mediaTile.dragY = mediaTile.y
            startX = mouse.x
            startY = mouse.y
        }
        onPositionChanged: (mouse) => {
            if (mediaTile.isDragging) {
                mediaTile.dragX += mouse.x - startX
                mediaTile.dragY += mouse.y - startY
            }
        }
        onReleased: {
            if (mediaTile.isDragging) contentWrapper.handleTileDrop(mediaTile)
        }
    }

    MouseArea {
        id: resizeHandle
        width: 24
        height: 24
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        z: 10
        enabled: dialogRoot.editMode && !mediaTile.inDrawer
        visible: dialogRoot.editMode && !mediaTile.inDrawer
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

        onPressed: (mouse) => {
            startAbsX = resizeHandle.mapToItem(contentWrapper, mouse.x, mouse.y).x
            mouse.accepted = true
        }
        onPositionChanged: (mouse) => {
            let absX = resizeHandle.mapToItem(contentWrapper, mouse.x, mouse.y).x
            let deltaX = absX - startAbsX
            let threshold = contentWrapper.cellW * 0.8

            if (deltaX > threshold && mediaTile.spanCols === 2) {
                mediaTile.gridCol = 0
                mediaTile.spanCols = 4
                contentWrapper.resolveCollisions(mediaTile)
                contentWrapper.applyGravity()
                dialogRoot.saveTileLayout()
                startAbsX = absX
            } else if (deltaX < -threshold && mediaTile.spanCols === 4) {
                mediaTile.spanCols = 2
                contentWrapper.applyGravity()
                dialogRoot.saveTileLayout()
                startAbsX = absX
            }
        }
    }
}
