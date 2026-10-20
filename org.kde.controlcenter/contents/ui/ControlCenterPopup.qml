import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.user.blurhelper 1.0

PlasmaCore.Dialog {
    id: dialogRoot
    title: "ControlCenterPopup"
    type: PlasmaCore.Dialog.OnScreenDisplay
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Dialog.NoBackground

    property bool editMode: false
    readonly property var blur: blurLoader.item || { update: function(){} }
    readonly property real uiScale: Math.max(0.5, Math.min(2.5, Plasmoid.configuration.uiScale || 1.0))
    readonly property color tileBaseColor: Qt.rgba(Plasmoid.configuration.tileColor.r, Plasmoid.configuration.tileColor.g, Plasmoid.configuration.tileColor.b, Plasmoid.configuration.tileAlpha)
    readonly property color activeTileColor: Plasmoid.configuration.activeTileColor || "#ffffff"
    readonly property color activeIconColor: Plasmoid.configuration.activeIconColor || "#000000"
    readonly property color inactiveIconColor: Plasmoid.configuration.inactiveIconColor || "#ffffff"
    readonly property color textColor: Plasmoid.configuration.textColor || "#ffffff"

    readonly property bool enableBlur: Plasmoid.configuration.enableBlur !== undefined ? Plasmoid.configuration.enableBlur : true
    readonly property int animStyle: Plasmoid.configuration.animStyle !== undefined ? Plasmoid.configuration.animStyle : 0

    readonly property bool showBorder: Plasmoid.configuration.showBorder
    readonly property color tileBorderColor: !showBorder ? "transparent" : Qt.rgba(Plasmoid.configuration.borderColor.r, Plasmoid.configuration.borderColor.g, Plasmoid.configuration.borderColor.b, Plasmoid.configuration.borderAlpha)
    readonly property int tileBorderWidth: showBorder ? Plasmoid.configuration.borderWidth : 0
    readonly property bool showShadow: Plasmoid.configuration.showShadow
    readonly property color shadowColor: Qt.rgba(Plasmoid.configuration.shadowColor.r, Plasmoid.configuration.shadowColor.g, Plasmoid.configuration.shadowColor.b, Plasmoid.configuration.shadowAlpha)
    readonly property int computedShadowSize: Math.max(0, Plasmoid.configuration.shadowSize + Plasmoid.configuration.shadowSmoothing)
    readonly property real speedMultiplier: Math.max(0.2, Plasmoid.configuration.animSpeed)
    readonly property int cfgRadius: Plasmoid.configuration.tileRadius
    readonly property int tileSpacing: Plasmoid.configuration.tileSpacing
    readonly property int edgeMargin: Plasmoid.configuration.edgeMargin
    readonly property int panelHeightOffset: Plasmoid.configuration.panelHeightOffset
    readonly property bool isBottomLeft: Plasmoid.configuration.popupPosition === 1
    readonly property int tileFillMode: Plasmoid.configuration.tileFillMode !== undefined ? Plasmoid.configuration.tileFillMode : 0
    readonly property real iconScale: Math.max(0.5, Math.min(2.5, Plasmoid.configuration.iconScale || 1.0))

    property bool wifiStatus: true
    property string wifiSsid: ""
    property bool btStatus: true
    property bool dndStatus: false
    property bool micMuted: false
    property bool audioMuted: false
    property string powerProfile: "balanced"
    property bool nightLightStatus: false
    property int batteryPercent: 100
    property bool batteryCharging: false
    property real brightnessRatio: 0.8
    property real volumeRatio: 0.5
    property bool kbdLightStatus: false
    property bool airplaneStatus: false
    property var defaultSink: null

    property string mediaTitle: "Not playing"
    property string mediaArtist: ""
    property string mediaStatus: "Stopped"
    property string mediaArtUrl: ""
    property real mediaPosition: 0
    property real mediaLength: 0

    signal runCommand(string cmd)
    signal setVolumeRatio(real ratio)
    signal setBrightnessRatio(int pct)
    signal toggleWifi()
    signal toggleBluetooth()
    signal toggleDnd()
    signal toggleMic()
    signal toggleAudioMute()
    signal setPerformanceMode(string mode)
    signal toggleNightLight()
    signal toggleKbdBacklight()
    signal toggleAirplaneMode()
    signal openColorPicker()
    signal openClipboard()
    signal openScreenshot()
    signal openKdeConnect()
    signal openPowerMenu()
    signal openSettings()

    property bool _isClosing: false

    readonly property var allBentoTiles: [
        wifiTile, btTile, mediaTile, brightnessTile, volumeTile,
        brightnessTileH, volumeTileH,
        dndTile, kdeConnectTile, perfTile, saverTile, micTile,
        muteTile, nightTile, clipTile, shotTile, kbdTile, airplaneTile, colorTile
    ]

    function saveTileLayout() {
        let data = {}
        for (let i = 0; i < allBentoTiles.length; ++i) {
            let t = allBentoTiles[i]
            if (t && t.tileKey) {
                data[t.tileKey] = {
                    inDrawer: t.inDrawer,
                    gridCol: t.gridCol,
                    gridRow: t.gridRow,
                    drawerCol: t.drawerCol,
                    drawerRow: t.drawerRow,
                    spanCols: t.spanCols
                }
            }
        }
        if (Plasmoid.configuration && typeof Plasmoid.configuration.tilePositions !== "undefined") {
            Plasmoid.configuration.tilePositions = JSON.stringify(data)
        }
    }

    function loadTileLayout() {
        if (!Plasmoid.configuration || typeof Plasmoid.configuration.tilePositions === "undefined") return
            let raw = Plasmoid.configuration.tilePositions
            if (!raw || raw === "{}" || raw === "") return
                try {
                    let data = JSON.parse(raw)
                    for (let i = 0; i < allBentoTiles.length; ++i) {
                        let t = allBentoTiles[i]
                        if (t && t.tileKey && data[t.tileKey]) {
                            let d = data[t.tileKey]
                            t.inDrawer = d.inDrawer
                            t.gridCol = d.gridCol
                            t.gridRow = d.gridRow
                            t.drawerCol = d.drawerCol
                            t.drawerRow = d.drawerRow
                            if (d.spanCols !== undefined) t.spanCols = d.spanCols
                        }
                    }
                } catch(e) {}
    }

    function resetTileStates() {
        let allTiles = [powerTile, settingsTile, editTile, batteryTile].concat(allBentoTiles).filter(t => t)
        for (let i = 0; i < allTiles.length; ++i) {
            allTiles[i].baseOpacity = 0.0
            allTiles[i].animProgress = 0.0
            if (allTiles[i].enterAnim) allTiles[i].enterAnim.stop()
                if (allTiles[i].dismissAnim) allTiles[i].dismissAnim.stop()
        }
    }

    function triggerCascades(isEntering) {
        let allTiles = [powerTile, settingsTile, editTile, batteryTile].concat(allBentoTiles).filter(t => t)
        let originX = isBottomLeft ? 0 : contentWrapper.width
        let originY = contentWrapper.height
        let tileData = []
        let maxDist = 0

        for (let i = 0; i < allTiles.length; i++) {
            let t = allTiles[i]
            let tx = ('targetX' in t) ? t.targetX : t.x
            let ty = ('targetY' in t) ? t.targetY : t.y
            let cx = tx + (t.width / 2)
            let cy = ty + (t.height / 2)
            let dist = Math.sqrt(Math.pow(cx - originX, 2) + Math.pow(cy - originY, 2))
            if (dist > maxDist) maxDist = dist
                tileData.push({ tile: t, dist: dist })
        }

        let maxDelayMs = Math.round(250 / speedMultiplier)
        for (let i = 0; i < tileData.length; i++) {
            let delayFactor = 1.0 - (maxDist > 0 ? (tileData[i].dist / maxDist) : 0)
            tileData[i].tile.triggerAnim(isEntering, Math.round(delayFactor * maxDelayMs))
        }

        if (!isEntering) {
            dismissFinishTimer.interval = maxDelayMs + Math.round(150 / speedMultiplier) + 50
            dismissFinishTimer.restart()
        }
    }

    function closeWithAnim() {
        if (!dialogRoot.visible || _isClosing) return
            _isClosing = true
            editMode = false
            dialogRoot.triggerCascades(false)
    }

    function repositionDialog() {
        let sm = (container && container.shadowMargin) ? Math.round(container.shadowMargin * uiScale) : 0
        x = isBottomLeft ? Math.round(edgeMargin - sm) : Math.round(Screen.width - width - edgeMargin + sm)
        y = Math.round(Screen.height - height - panelHeightOffset - edgeMargin + sm)
    }

    onActiveChanged: {
        if (!active && visible && !_isClosing) {
            closeWithAnim()
        }
    }

    onVisibleChanged: {
        if (!visible) {
            editMode = false
            resetTileStates()
            _isClosing = false
        } else {
            _isClosing = false
            repositionDialog()
            resetTileStates()
            requestActivate()
            dialogRoot.triggerCascades(true)
        }
    }

    readonly property int calculatedRows: {
        let maxR = 0
        for (let i = 0; i < allBentoTiles.length; ++i) {
            let t = allBentoTiles[i]
            if (t && !t.inDrawer) {
                maxR = Math.max(maxR, t.gridRow + t.spanRows)
            }
        }
        let maxDrawerR = 0
        if (editMode) {
            for (let i = 0; i < allBentoTiles.length; ++i) {
                let t = allBentoTiles[i]
                if (t && t.inDrawer) {
                    maxDrawerR = Math.max(maxDrawerR, t.drawerRow + t.spanRows)
                }
            }
        }
        return editMode ? Math.max(maxR + 1, maxDrawerR) : Math.max(1, maxR)
    }

    Component.onCompleted: {
        loadTileLayout()
        contentWrapper.updateDrawerLayout()
        contentWrapper.applyGravity()
    }

    mainItem: FocusScope {
        id: container
        readonly property int shadowMargin: Math.max(48, dialogRoot.computedShadowSize + 16)
        width: Math.round((contentWrapper.width + shadowMargin * 2) * dialogRoot.uiScale)
        height: Math.round((contentWrapper.height + shadowMargin * 2) * dialogRoot.uiScale)
        focus: true

        Timer {
            id: dismissFinishTimer
            onTriggered: {
                dialogRoot.visible = false
                dialogRoot._isClosing = false
            }
        }

        onWidthChanged: dialogRoot.repositionDialog()
        onHeightChanged: dialogRoot.repositionDialog()
        Loader {
            id: blurLoader
            active: dialogRoot.visible && dialogRoot.enableBlur
            sourceComponent: Component {
                BlurHelper {
                    window: dialogRoot
                    active: dialogRoot.visible && dialogRoot.enableBlur
                    tiles: [
                        powerTile, settingsTile, editTile, batteryTile, tileDrawer,
                        wifiTile, btTile, mediaTile, brightnessTile, volumeTile,
                        brightnessTileH, volumeTileH,
                        dndTile, kdeConnectTile, perfTile, saverTile, micTile,
                        muteTile, nightTile, clipTile, shotTile, kbdTile, airplaneTile, colorTile
                    ]
                }
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                if (dialogRoot.editMode) {
                    dialogRoot.editMode = false
                } else {
                    dialogRoot.closeWithAnim()
                }
                event.accepted = true
            }
        }

        Item {
            id: contentWrapper

            property real drawerAnimProgress: dialogRoot.editMode ? 1.0 : 0.0
            Behavior on drawerAnimProgress {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutQuart
                }
            }

            width: 336 + ((180 + dialogRoot.tileSpacing) * drawerAnimProgress)
            height: headerRow.height + dialogRoot.tileSpacing + gridArea.height + 16

            scale: dialogRoot.uiScale
            transformOrigin: dialogRoot.isBottomLeft ? Item.BottomLeft : Item.BottomRight

            anchors.bottom: parent.bottom
            anchors.bottomMargin: container.shadowMargin
            anchors.right: dialogRoot.isBottomLeft ? undefined : parent.right
            anchors.rightMargin: dialogRoot.isBottomLeft ? 0 : container.shadowMargin
            anchors.left: dialogRoot.isBottomLeft ? parent.left : undefined
            anchors.leftMargin: dialogRoot.isBottomLeft ? container.shadowMargin : 0

            readonly property real cellW: Math.round((336 - 3 * dialogRoot.tileSpacing) / 4)
            readonly property real cellH: cellW

            function getGridX(c) { return Math.round(gridArea.x + c * (cellW + dialogRoot.tileSpacing)) }
            function getGridY(r) { return Math.round(gridArea.y + r * (cellH + dialogRoot.tileSpacing)) }
            function getGridW(sc) { return Math.round(sc * cellW + (sc - 1) * dialogRoot.tileSpacing) }
            function getGridH(sr) { return Math.round(sr * cellH + (sr - 1) * dialogRoot.tileSpacing) }
            function getDrawerX(c) { return Math.round(tileDrawer.x + 12 + c * (cellW + dialogRoot.tileSpacing)) }
            function getDrawerY(r) { return Math.round(tileDrawer.y + 44 + r * (cellH + dialogRoot.tileSpacing)) }

            function updateDrawerLayout() {
                let drawerTiles = dialogRoot.allBentoTiles.filter(t => t && t.inDrawer)
                let grid = []
                for (let i = 0; i < 50; i++) grid.push([false, false])

                    for (let i = 0; i < drawerTiles.length; i++) {
                        let t = drawerTiles[i]
                        let placed = false
                        for (let r = 0; r < 50 && !placed; r++) {
                            for (let c = 0; c < 2 && !placed; c++) {
                                let free = true
                                for (let rr = 0; rr < t.spanRows; rr++) {
                                    for (let cc = 0; cc < t.spanCols; cc++) {
                                        if (c + cc >= 2 || grid[r + rr][c + cc]) {
                                            free = false
                                        }
                                    }
                                }
                                if (free) {
                                    t.drawerCol = c
                                    t.drawerRow = r
                                    for (let rr = 0; rr < t.spanRows; rr++) {
                                        for (let cc = 0; cc < t.spanCols; cc++) {
                                            grid[r + rr][c + cc] = true
                                        }
                                    }
                                    placed = true
                                }
                            }
                        }
                    }
            }

            function applyGravity() {
                let gridTiles = dialogRoot.allBentoTiles.filter(t => t && !t.inDrawer)
                let changed = true
                let loops = 0
                while (changed && loops < 50) {
                    changed = false
                    loops++
                    gridTiles.sort((a, b) => {
                        if (a.gridRow === b.gridRow) return a.gridCol - b.gridCol
                            return a.gridRow - b.gridRow
                    })
                    for (let i = 0; i < gridTiles.length; i++) {
                        let t = gridTiles[i]
                        if (t.gridRow > 0) {
                            t.gridRow--
                            let col = false
                            for (let j = 0; j < gridTiles.length; j++) {
                                if (i === j) continue
                                    let ot = gridTiles[j]
                                    if (t.gridCol < ot.gridCol + ot.spanCols &&
                                        t.gridCol + t.spanCols > ot.gridCol &&
                                        t.gridRow < ot.gridRow + ot.spanRows &&
                                        t.gridRow + t.spanRows > ot.gridRow) {
                                        col = true
                                        break
                                        }
                            }
                            if (col) {
                                t.gridRow++
                            } else {
                                changed = true
                            }
                        }
                    }
                }
            }

            function resolveCollisions(movedTile) {
                let gridTiles = dialogRoot.allBentoTiles.filter(t => t && !t.inDrawer)
                let changed = true
                let loops = 0
                while (changed && loops < 30) {
                    changed = false
                    loops++
                    for (let i = 0; i < gridTiles.length; i++) {
                        let a = gridTiles[i]
                        for (let j = 0; j < gridTiles.length; j++) {
                            if (i === j) continue
                                let b = gridTiles[j]
                                if (a.gridCol < b.gridCol + b.spanCols &&
                                    a.gridCol + a.spanCols > b.gridCol &&
                                    a.gridRow < b.gridRow + b.spanRows &&
                                    a.gridRow + a.spanRows > b.gridRow) {

                                    if (a === movedTile) {
                                        b.gridRow = a.gridRow + a.spanRows
                                    } else if (b === movedTile) {
                                        a.gridRow = b.gridRow + b.spanRows
                                    } else if (a.gridRow <= b.gridRow) {
                                        b.gridRow = a.gridRow + a.spanRows
                                    } else {
                                        a.gridRow = b.gridRow + b.spanRows
                                    }
                                    changed = true
                                    }
                        }
                    }
                }
            }
            function formatArtUrl(url) {
                if (!url || url === "") return ""
                    // Handle local paths without file:// prefix
                    if (url.startsWith("/")) return "file://" + url
                        return url
            }
            function handleTileDrop(dragged) {
                let cX = dragged.x + dragged.width / 2
                let cY = dragged.y + dragged.height / 2

                if (cX >= tileDrawer.x) {
                    if (dragged.tileKey === "media" && dragged.spanCols > 2) dragged.spanCols = 2

                        dragged.inDrawer = true
                        updateDrawerLayout()
                        applyGravity()
                        dragged.isDragging = false
                        dragged.dragX = dragged.targetX
                        dragged.dragY = dragged.targetY
                        blur.update()
                        dialogRoot.saveTileLayout()
                        return
                }

                let relX = Math.max(0, dragged.x - gridArea.x)
                let relY = Math.max(0, dragged.y - gridArea.y)
                let targetCol = Math.max(0, Math.min(4 - dragged.spanCols, Math.round(relX / (cellW + dialogRoot.tileSpacing))))
                let targetRow = Math.max(0, Math.round(relY / (cellH + dialogRoot.tileSpacing)))

                let wasInDrawer = dragged.inDrawer
                let oC = dragged.gridCol
                let oR = dragged.gridRow

                dragged.inDrawer = false
                dragged.gridCol = targetCol
                dragged.gridRow = targetRow

                let gridTiles = dialogRoot.allBentoTiles.filter(t => t && !t.inDrawer && t !== dragged)
                let swapTarget = null
                if (!wasInDrawer) {
                    for (let i = 0; i < gridTiles.length; i++) {
                        let t = gridTiles[i]
                        if (t.spanCols === dragged.spanCols && t.spanRows === dragged.spanRows && t.gridCol === targetCol && t.gridRow === targetRow) {
                            swapTarget = t
                            break
                        }
                    }
                }

                if (swapTarget) {
                    swapTarget.gridCol = oC
                    swapTarget.gridRow = oR
                } else {
                    resolveCollisions(dragged)
                }

                applyGravity()

                if (wasInDrawer) {
                    updateDrawerLayout()
                }

                dragged.isDragging = false
                dragged.dragX = dragged.targetX
                dragged.dragY = dragged.targetY
                blur.update()
                dialogRoot.saveTileLayout()
            }

            // ================= HEADER ROW =================
            RowLayout {
                id: headerRow
                anchors.top: parent.top
                anchors.left: parent.left
                width: 336
                height: 38
                spacing: 8

                HeaderButton {
                    id: powerTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    iconSource: "system-shutdown"
                    tooltipText: "Power"
                    onClicked: dialogRoot.openPowerMenu()
                }

                HeaderButton {
                    id: settingsTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    iconSource: "settings-configure"
                    tooltipText: "Settings"
                    onClicked: dialogRoot.openSettings()
                }

                HeaderButton {
                    id: editTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    isEditButton: true
                    iconSource: dialogRoot.editMode ? "dialog-ok-apply" : "document-edit"
                    tooltipText: dialogRoot.editMode ? "Done Editing" : "Edit Grid"
                    onClicked: dialogRoot.editMode = !dialogRoot.editMode
                }

                Item { Layout.fillWidth: true }

                HeaderBattery {
                    id: batteryTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                }
            }

            // Background Bento Grid slot indicator guides
            Item {
                id: gridArea
                anchors.top: headerRow.bottom
                anchors.topMargin: dialogRoot.tileSpacing
                anchors.left: parent.left
                width: 336

                readonly property real targetHeight: Math.max(0, Math.round((dialogRoot.calculatedRows * contentWrapper.cellH) + ((dialogRoot.calculatedRows - 1) * dialogRoot.tileSpacing)))
                height: targetHeight
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

                Repeater {
                    model: dialogRoot.calculatedRows * 4
                    delegate: Rectangle {
                        readonly property int r: Math.floor(index / 4)
                        readonly property int c: index % 4
                        x: Math.round(c * (contentWrapper.cellW + dialogRoot.tileSpacing))
                        y: Math.round(r * (contentWrapper.cellH + dialogRoot.tileSpacing))
                        width: contentWrapper.cellW
                        height: contentWrapper.cellH
                        radius: dialogRoot.cfgRadius
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.color: Qt.rgba(1, 1, 1, 0.16)
                        border.width: 1
                        visible: dialogRoot.editMode
                    }
                }
            }

            // Tile Drawer Background
            Kirigami.ShadowedRectangle {
                id: tileDrawer
                anchors.top: parent.top
                anchors.left: gridArea.right
                anchors.leftMargin: dialogRoot.tileSpacing
                width: 180
                height: headerRow.height + dialogRoot.tileSpacing + gridArea.height
                radius: dialogRoot.cfgRadius
                color: Qt.rgba(0.08, 0.08, 0.08, 0.65)
                border.color: Qt.rgba(1, 1, 1, 0.18)
                border.width: 1

                visible: contentWrapper.drawerAnimProgress > 0
                opacity: contentWrapper.drawerAnimProgress
                clip: false
                z: 0

                shadow {
                    size: dialogRoot.showShadow ? dialogRoot.computedShadowSize : 0
                    color: dialogRoot.showShadow ? dialogRoot.shadowColor : "transparent"
                    xOffset: 0
                    yOffset: 0
                }

                PlasmaComponents.Label {
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Tile Drawer"
                    font.pixelSize: 11
                    font.bold: true
                    opacity: 0.7
                    color: dialogRoot.textColor
                }
            }

            // ================= ALL BENTO TILES =================
            BentoToggleTile {
                id: wifiTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "wifi"
                inDrawer: false
                gridCol: 0
                gridRow: 0
                spanCols: 2
                tileName: dialogRoot.wifiStatus && dialogRoot.wifiSsid !== "" ? dialogRoot.wifiSsid : "Wi-Fi"
                subtitleText: dialogRoot.wifiStatus ? "Connected" : "Off"
                iconSource: "network-wireless-symbolic"
                activeState: dialogRoot.wifiStatus
                onTileClicked: dialogRoot.toggleWifi()
            }

            BentoToggleTile {
                id: btTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "bluetooth"
                inDrawer: false
                gridCol: 2
                gridRow: 0
                spanCols: 2
                tileName: "Bluetooth"
                subtitleText: dialogRoot.btStatus ? "On" : "Off"
                iconSource: "preferences-system-bluetooth"
                activeState: dialogRoot.btStatus
                onTileClicked: dialogRoot.toggleBluetooth()
            }

            BentoMediaTile {
                id: mediaTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                inDrawer: false
                gridCol: 0
                gridRow: 1
            }

            BentoSliderTile {
                id: brightnessTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "brightness"
                inDrawer: false
                gridCol: 2
                gridRow: 1
                currentRatio: dialogRoot.brightnessRatio
                iconSource: "brightness-high"
                tooltipText: "Screen Brightness"
                clampBottom: true
                onRatioSet: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                onRatioReleased: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                Connections {
                    target: dialogRoot
                    function onBrightnessRatioChanged() {
                        if (!brightnessTile.isSliderPressed && dialogRoot.brightnessRatio > 0) {
                            brightnessTile.currentRatio = dialogRoot.brightnessRatio
                        }
                    }
                }
            }

            BentoSliderTile {
                id: volumeTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "volume"
                inDrawer: false
                gridCol: 3
                gridRow: 1
                currentRatio: dialogRoot.volumeRatio
                iconSource: (dialogRoot.volumeRatio > 0.5) ? "audio-volume-high" : (dialogRoot.volumeRatio > 0.05) ? "audio-volume-medium" : "audio-volume-muted"
                tooltipText: "Volume"
                clampBottom: false
                onRatioSet: (r) => dialogRoot.setVolumeRatio(r)
                onRatioReleased: (r) => dialogRoot.setVolumeRatio(r)
                Connections {
                    target: dialogRoot
                    function onVolumeRatioChanged() {
                        if (!volumeTile.isSliderPressed && dialogRoot.volumeRatio >= 0) {
                            volumeTile.currentRatio = dialogRoot.volumeRatio
                        }
                    }
                }
            }

            // Alternate Horizontal Sliders
            BentoSliderTile {
                id: brightnessTileH
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "brightness_h"
                inDrawer: true
                spanCols: 2
                spanRows: 1
                currentRatio: dialogRoot.brightnessRatio
                iconSource: "brightness-high"
                tooltipText: "Screen Brightness"
                clampBottom: true
                onRatioSet: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                onRatioReleased: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                Connections {
                    target: dialogRoot
                    function onBrightnessRatioChanged() {
                        if (!brightnessTileH.isSliderPressed && dialogRoot.brightnessRatio > 0) {
                            brightnessTileH.currentRatio = dialogRoot.brightnessRatio
                        }
                    }
                }
            }

            BentoSliderTile {
                id: volumeTileH
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "volume_h"
                inDrawer: true
                spanCols: 2
                spanRows: 1
                currentRatio: dialogRoot.volumeRatio
                iconSource: (dialogRoot.volumeRatio > 0.5) ? "audio-volume-high" : (dialogRoot.volumeRatio > 0.05) ? "audio-volume-medium" : "audio-volume-muted"
                tooltipText: "Volume"
                clampBottom: false
                onRatioSet: (r) => dialogRoot.setVolumeRatio(r)
                onRatioReleased: (r) => dialogRoot.setVolumeRatio(r)
                Connections {
                    target: dialogRoot
                    function onVolumeRatioChanged() {
                        if (!volumeTileH.isSliderPressed && dialogRoot.volumeRatio >= 0) {
                            volumeTileH.currentRatio = dialogRoot.volumeRatio
                        }
                    }
                }
            }

            BentoToggleTile {
                id: dndTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "dnd"
                inDrawer: false
                gridCol: 0
                gridRow: 3
                spanCols: 2
                tileName: "Do Not Disturb"
                subtitleText: dialogRoot.dndStatus ? "On" : "Off"
                iconSource: dialogRoot.dndStatus ? "notifications-disabled" : "notifications"
                activeState: dialogRoot.dndStatus
                onTileClicked: dialogRoot.toggleDnd()
            }

            BentoToggleTile {
                id: kdeConnectTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "kdeconnect"
                inDrawer: false
                gridCol: 2
                gridRow: 3
                spanCols: 2
                tileName: "KDE Connect"
                subtitleText: "Open"
                iconSource: "kdeconnect"
                activeState: false
                onTileClicked: dialogRoot.openKdeConnect()
            }

            // Drawer Toggle Tiles
            BentoToggleTile {
                id: perfTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "performance"
                tileName: "Performance Mode"
                drawerCol: 0
                drawerRow: 0
                iconSource: "power-profile-performance"
                activeState: dialogRoot.powerProfile === "performance"
                onTileClicked: dialogRoot.setPerformanceMode(dialogRoot.powerProfile === "performance" ? "balanced" : "performance")
            }

            BentoToggleTile {
                id: saverTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "powersaver"
                tileName: "Battery Saver"
                drawerCol: 1
                drawerRow: 0
                iconSource: "battery-profile-powersave"
                activeState: dialogRoot.powerProfile === "power-saver"
                onTileClicked: dialogRoot.setPerformanceMode(dialogRoot.powerProfile === "power-saver" ? "balanced" : "power-saver")
            }

            BentoToggleTile {
                id: micTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "microphone"
                tileName: "Microphone"
                drawerCol: 0
                drawerRow: 1
                iconSource: dialogRoot.micMuted ? "microphone-sensitivity-muted" : "audio-input-microphone"
                activeState: dialogRoot.micMuted
                onTileClicked: dialogRoot.toggleMic()
            }

            BentoToggleTile {
                id: muteTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "muteaudio"
                tileName: "Mute Audio"
                drawerCol: 1
                drawerRow: 1
                iconSource: dialogRoot.audioMuted ? "audio-volume-muted" : "audio-volume-high"
                activeState: dialogRoot.audioMuted
                onTileClicked: dialogRoot.toggleAudioMute()
            }

            BentoToggleTile {
                id: nightTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "nightlight"
                tileName: "Night Light"
                drawerCol: 0
                drawerRow: 2
                iconSource: "redshift-status-on"
                activeState: dialogRoot.nightLightStatus
                onTileClicked: dialogRoot.toggleNightLight()
            }

            BentoToggleTile {
                id: clipTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "clipboard"
                tileName: "Clipboard"
                drawerCol: 1
                drawerRow: 2
                iconSource: "klipper"
                activeState: false
                onTileClicked: dialogRoot.openClipboard()
            }

            BentoToggleTile {
                id: shotTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "screenshot"
                tileName: "Screenshot"
                drawerCol: 0
                drawerRow: 3
                iconSource: "spectacle"
                activeState: false
                onTileClicked: dialogRoot.openScreenshot()
            }

            BentoToggleTile {
                id: kbdTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "keyboardbacklight"
                tileName: "Keyboard Backlight"
                drawerCol: 1
                drawerRow: 3
                iconSource: "input-keyboard"
                activeState: dialogRoot.kbdLightStatus
                onTileClicked: dialogRoot.toggleKbdBacklight()
            }

            BentoToggleTile {
                id: airplaneTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "airplanemode"
                tileName: "Airplane Mode"
                drawerCol: 0
                drawerRow: 4
                iconSource: dialogRoot.airplaneStatus ? "network-flightmode-on" : "network-flightmode-off"
                activeState: dialogRoot.airplaneStatus
                onTileClicked: dialogRoot.toggleAirplaneMode()
            }

            BentoToggleTile {
                id: colorTile
                dialogRoot: dialogRoot
                contentWrapper: contentWrapper
                blurHelper: blur
                tileKey: "colorpicker"
                tileName: "Color Picker"
                drawerCol: 1
                drawerRow: 4
                iconSource: "color-picker"
                activeState: false
                onTileClicked: dialogRoot.openColorPicker()
            }
        }
    }
}
