import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: deviceView
    property var dialogRoot
    property var blurHelper
    property bool isWifi: true
    property list<Item> activeTiles: []

    visible: opacity > 0
    opacity: dialogRoot.activeSubView === (isWifi ? "wifi" : "bluetooth") ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
    onOpacityChanged: if (blurHelper) blurHelper.update()

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

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
                    xOffset: 0
                    yOffset: 0
                }

                Component.onCompleted: {
                    deviceView.activeTiles.push(backBtnRect)
                    if (blurHelper) blurHelper.update()
                }
                Component.onDestruction: {
                    let idx = deviceView.activeTiles.indexOf(backBtnRect)
                    if (idx !== -1) deviceView.activeTiles.splice(idx, 1)
                        if (blurHelper) blurHelper.update()
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "go-previous"
                    width: 18
                    height: width
                    color: dialogRoot.textColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        deviceView.activeTiles = []
                        if (blurHelper) blurHelper.update()
                            dialogRoot.activeSubView = ""
                    }
                }
            }

            Kirigami.ShadowedRectangle {
                id: refreshBtnRect
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
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
                    deviceView.activeTiles.push(refreshBtnRect)
                    if (blurHelper) blurHelper.update()
                }
                Component.onDestruction: {
                    let idx = deviceView.activeTiles.indexOf(refreshBtnRect)
                    if (idx !== -1) deviceView.activeTiles.splice(idx, 1)
                        if (blurHelper) blurHelper.update()
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "view-refresh"
                    width: 18
                    height: width
                    color: dialogRoot.textColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (isWifi) {
                            dialogRoot.runCommand("nmcli device wifi rescan")
                        } else {
                            dialogRoot.runCommand("bluetoothctl scan on")
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Kirigami.ShadowedRectangle {
                id: disconnectBtnRect
                Layout.preferredWidth: 150
                Layout.preferredHeight: 40
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
                    deviceView.activeTiles.push(disconnectBtnRect)
                    if (blurHelper) blurHelper.update()
                }
                Component.onDestruction: {
                    let idx = deviceView.activeTiles.indexOf(disconnectBtnRect)
                    if (idx !== -1) deviceView.activeTiles.splice(idx, 1)
                        if (blurHelper) blurHelper.update()
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8

                    Kirigami.Icon {
                        source: isWifi ? "network-disconnect" : "bluetooth-disconnected"
                        width: 16
                        height: width
                        color: dialogRoot.textColor
                    }

                    PlasmaComponents.Label {
                        text: "Disconnect"
                        font.pixelSize: 12
                        font.bold: true
                        color: dialogRoot.textColor
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (isWifi) dialogRoot.disconnectWifi()
                            else dialogRoot.disconnectBluetooth("")
                                deviceView.activeTiles = []
                                if (blurHelper) blurHelper.update()
                                    dialogRoot.activeSubView = ""
                    }
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            interactive: false
            flickableDirection: Flickable.AutoFlickIfNeeded
            boundsBehavior: Flickable.StopAtBounds
            verticalLayoutDirection: ListView.BottomToTop
            model: isWifi ? dialogRoot.wifiNetworkList : dialogRoot.bluetoothDeviceList

            onContentYChanged: if (blurHelper) blurHelper.update()
            onMovementEnded: if (blurHelper) blurHelper.update()

            delegate: Item {
                width: listView.width
                height: 56

                Kirigami.ShadowedRectangle {
                    id: itemRect
                    anchors.fill: parent
                    radius: dialogRoot.cfgRadius
                    color: (isWifi && modelData.active) || (!isWifi && modelData.connected)
                    ? dialogRoot.activeTileColor
                    : dialogRoot.tileBaseColor
                    border.color: dialogRoot.tileBorderColor
                    border.width: dialogRoot.tileBorderWidth

                    scale: deviceView.opacity > 0 ? 1.0 : 0.9
                    opacity: deviceView.opacity > 0 ? 1.0 : 0.0
                    Behavior on scale {
                        NumberAnimation { duration: 250 / dialogRoot.speedMultiplier; easing.type: Easing.OutBack }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200 / dialogRoot.speedMultiplier; easing.type: Easing.OutQuad }
                    }

                    shadow {
                        size: dialogRoot.showShadow ? dialogRoot.computedShadowSize : 0
                        color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
                        xOffset: 0
                        yOffset: 0
                    }

                    Component.onCompleted: {
                        deviceView.activeTiles.push(itemRect)
                        if (blurHelper) blurHelper.update()
                    }
                    Component.onDestruction: {
                        let idx = deviceView.activeTiles.indexOf(itemRect)
                        if (idx !== -1) deviceView.activeTiles.splice(idx, 1)
                            if (blurHelper) blurHelper.update()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 14

                        Kirigami.Icon {
                            source: isWifi ? "network-wireless" : "bluetooth"
                            width: 22
                            height: width
                            color: (isWifi && modelData.active) || (!isWifi && modelData.connected)
                            ? dialogRoot.activeIconColor
                            : dialogRoot.textColor
                        }

                        PlasmaComponents.Label {
                            text: isWifi ? modelData.ssid : modelData.name
                            font.pixelSize: 13
                            font.bold: (isWifi && modelData.active) || (!isWifi && modelData.connected)
                            color: (isWifi && modelData.active) || (!isWifi && modelData.connected)
                            ? dialogRoot.activeIconColor
                            : dialogRoot.textColor
                            Layout.fillWidth: true
                        }

                        PlasmaComponents.Label {
                            text: isWifi ? (modelData.strength + "%") : (modelData.connected ? "Connected" : "")
                            font.pixelSize: 11
                            opacity: 0.7
                            color: (isWifi && modelData.active) || (!isWifi && modelData.connected)
                            ? dialogRoot.activeIconColor
                            : dialogRoot.textColor
                            visible: text !== ""
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isWifi) dialogRoot.connectWifi(modelData.ssid)
                                else dialogRoot.connectBluetooth(modelData.mac)
                                    deviceView.activeTiles = []
                                    if (blurHelper) blurHelper.update()
                                        dialogRoot.activeSubView = ""
                        }
                    }
                }
            }
        }
    }
}
