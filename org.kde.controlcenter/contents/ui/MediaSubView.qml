import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Kirigami.ShadowedRectangle {
    id: mediaSubView
    property var dialogRoot
    property var blurHelper
    property var activeTiles: []

    visible: opacity > 0
    opacity: dialogRoot.activeSubView === "media" ? 1.0 : 0.0
    scale: opacity > 0 ? 1.0 : 0.95

    Behavior on opacity {
        NumberAnimation { duration: 200 / dialogRoot.speedMultiplier; easing.type: Easing.OutQuad }
    }
    Behavior on scale {
        NumberAnimation { duration: 250 / dialogRoot.speedMultiplier; easing.type: Easing.OutBack }
    }
    onOpacityChanged: if (blurHelper) blurHelper.update()

    radius: dialogRoot.cfgRadius
    color: dialogRoot.tileBaseColor
    border.color: dialogRoot.tileBorderColor
    border.width: dialogRoot.tileBorderWidth

    shadow {
        size: dialogRoot.showShadow ? dialogRoot.computedShadowSize : 0
        color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
        xOffset: 0
        yOffset: 0
    }

    Component.onCompleted: {
        if (!mediaSubView.activeTiles.includes(mediaSubView)) {
            mediaSubView.activeTiles.push(mediaSubView)
        }
        if (blurHelper) blurHelper.update()
    }
    Component.onDestruction: {
        let idx = mediaSubView.activeTiles.indexOf(mediaSubView)
        if (idx !== -1) mediaSubView.activeTiles.splice(idx, 1)
            if (blurHelper) blurHelper.update()
    }

    function formatTime(s) {
        if (isNaN(s) || s <= 0) return "0:00"
            let mins = Math.floor(s / 60)
            let secs = Math.floor(s % 60)
            return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    // Height the popup needs to show everything, including ALL audio outputs.
    // Grows automatically when a new output (e.g. bluetooth earbuds) shows up.
    readonly property int sinkCount: (dialogRoot.audioSinks || []).length
    readonly property real sinkRowH: 42
    readonly property real sinkRowGap: 6
    readonly property real wantedHeight: {
        const gap = mediaLayout.spacing
        const listH = sinkCount > 0 ? sinkCount * sinkRowH + (sinkCount - 1) * sinkRowGap + audioOutputsList.bottomMargin : 0
        return 16                                   // top margin
        + 40 + gap                             // navigation bar
        + (mediaSubView.width - 32) + gap      // square album art
        + mediaTitleCol.implicitHeight + gap   // title / artist
        + mediaScrubCol.implicitHeight + gap   // scrubber + times
        + 48 + gap                             // play / pause row
        + audioHeaderLabel.implicitHeight + 6  // "Audio Output" label
        + listH                                // one row per output
        + 16 + 6                               // bottom margin + safety
    }
    onHeightChanged: if (blurHelper) blurHelper.update()

    ColumnLayout {
        id: mediaLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Top Navigation Bar
        RowLayout {
            Layout.fillWidth: true
            height: 40
            spacing: 6

            Kirigami.ShadowedRectangle {
                id: backBtnRect
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: dialogRoot.tileBaseColor
                border.color: dialogRoot.tileBorderColor
                border.width: dialogRoot.tileBorderWidth

                shadow {
                    size: dialogRoot.showShadow ? dialogRoot.computedShadowSize : 0
                    color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
                    xOffset: 0; yOffset: 0
                }

                Component.onCompleted: {
                    if (!mediaSubView.activeTiles.includes(backBtnRect)) mediaSubView.activeTiles.push(backBtnRect)
                        if (blurHelper) blurHelper.update()
                }
                Component.onDestruction: {
                    let idx = mediaSubView.activeTiles.indexOf(backBtnRect)
                    if (idx !== -1) mediaSubView.activeTiles.splice(idx, 1)
                        if (blurHelper) blurHelper.update()
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "go-previous"
                    width: 18; height: width
                    color: dialogRoot.textColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mediaSubView.activeTiles = [mediaSubView]
                        if (blurHelper) blurHelper.update()
                            dialogRoot.activeSubView = ""
                    }
                }
            }

            PlasmaComponents.Label {
                text: "Now Playing"
                font.pixelSize: 14
                font.bold: true
                color: dialogRoot.textColor
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Item { width: 40 }
        }

        // Full Size Album Art (1:1 Aspect Ratio)
        Kirigami.ShadowedImage {
            id: bigAlbumArt
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: width
            radius: 16
            color: Qt.rgba(1, 1, 1, 0.08)
            border.color: dialogRoot.tileBorderColor
            border.width: 1

            shadow {
                size: dialogRoot.showShadow ? dialogRoot.computedShadowSize : 0
                color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
                xOffset: 0
                yOffset: 0
            }

            source: {
                let art = dialogRoot.mediaArtUrl || ""
                if (art === "") return ""
                    if (art.startsWith("/")) return "file://" + art
                        return art
            }
            fillMode: Image.PreserveAspectCrop

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 64; height: 64
                source: "media-default-album"
                color: dialogRoot.inactiveIconColor
                opacity: 0.45
                visible: bigAlbumArt.status !== Image.Ready || bigAlbumArt.source == ""
            }
        }

        // Centered Title and Artist
        ColumnLayout {
            id: mediaTitleCol
            Layout.fillWidth: true
            spacing: 2
            Layout.alignment: Qt.AlignHCenter

            PlasmaComponents.Label {
                text: dialogRoot.mediaTitle
                font.pixelSize: 15
                font.bold: true
                color: dialogRoot.textColor
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                text: dialogRoot.mediaArtist
                font.pixelSize: 12
                opacity: 0.65
                color: dialogRoot.textColor
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }
        }

        // Playback Scrubber Bar
        ColumnLayout {
            id: mediaScrubCol
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                height: 6; radius: 3
                color: Qt.rgba(1, 1, 1, 0.2)

                Rectangle {
                    width: dialogRoot.mediaLength > 0 ? parent.width * (dialogRoot.mediaPosition / dialogRoot.mediaLength) : 0
                    height: parent.height; radius: 3
                    color: dialogRoot.activeTileColor
                }

                MouseArea {
                    anchors.fill: parent; anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (dialogRoot.mediaLength > 0) {
                            let newPos = (mouse.x / parent.width) * dialogRoot.mediaLength
                            dialogRoot.runCommand("playerctl position " + newPos)
                            dialogRoot.mediaPosition = newPos
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents.Label {
                    text: mediaSubView.formatTime(dialogRoot.mediaPosition)
                    font.pixelSize: 10; color: dialogRoot.textColor; opacity: 0.7
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label {
                    text: "-" + mediaSubView.formatTime(dialogRoot.mediaLength - dialogRoot.mediaPosition)
                    font.pixelSize: 10; color: dialogRoot.textColor; opacity: 0.7
                }
            }
        }

        // Media Action Buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 32

            MouseArea {
                width: 36; height: 36; cursorShape: Qt.PointingHandCursor
                Kirigami.Icon { anchors.centerIn: parent; width: 22; height: width; source: "media-skip-backward"; color: dialogRoot.inactiveIconColor }
                onClicked: dialogRoot.runCommand("playerctl previous")
            }

            MouseArea {
                width: 48; height: 48; cursorShape: Qt.PointingHandCursor
                Rectangle {
                    anchors.fill: parent; radius: 24
                    color: dialogRoot.activeTileColor
                    Kirigami.Icon {
                        anchors.centerIn: parent; width: 24; height: width
                        source: dialogRoot.mediaStatus === "Playing" ? "media-playback-pause" : "media-playback-start"
                        color: dialogRoot.activeIconColor
                    }
                }
                onClicked: dialogRoot.runCommand("playerctl play-pause")
            }

            MouseArea {
                width: 36; height: 36; cursorShape: Qt.PointingHandCursor
                Kirigami.Icon { anchors.centerIn: parent; width: 22; height: width; source: "media-skip-forward"; color: dialogRoot.inactiveIconColor }
                onClicked: dialogRoot.runCommand("playerctl next")
            }
        }

        // Audio Output Selector Sinks
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            PlasmaComponents.Label {
                id: audioHeaderLabel
                text: "Audio Output"
                font.pixelSize: 11; font.bold: true; opacity: 0.7
                color: dialogRoot.textColor
            }

            ListView {
                id: audioOutputsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: dialogRoot.audioSinks || []
                spacing: mediaSubView.sinkRowGap
                clip: true
                bottomMargin: 12

                delegate: Kirigami.ShadowedRectangle {
                    width: audioOutputsList.width
                    height: mediaSubView.sinkRowH
                    radius: dialogRoot.cfgRadius
                    color: modelData.active ? dialogRoot.activeTileColor : dialogRoot.tileBaseColor
                    border.color: dialogRoot.tileBorderColor
                    border.width: dialogRoot.tileBorderWidth

                    shadow {
                        size: dialogRoot.showShadow ? dialogRoot.computedShadowSize : 0
                        color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
                        xOffset: 0; yOffset: 0
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        spacing: 10

                        Kirigami.Icon {
                            source: (modelData.name && modelData.name.toLowerCase().includes("blue")) ? "audio-headphones" : "audio-card"
                            width: 18; height: width
                            color: modelData.active ? dialogRoot.activeIconColor : dialogRoot.textColor
                        }

                        PlasmaComponents.Label {
                            text: modelData.description || modelData.name || "Audio Device"
                            font.pixelSize: 12
                            font.bold: modelData.active
                            color: modelData.active ? dialogRoot.activeIconColor : dialogRoot.textColor
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            dialogRoot.runCommand("pactl set-default-sink " + modelData.name)
                        }
                    }
                }
            }
        }
    }


}
