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
    // OnScreenDisplay windows never take focus, so we never got deactivated when the user clicked
    // another window. AppletPopup is activatable and behaves like a normal Plasma popup.
    type: PlasmaCore.Dialog.AppletPopup
    hideOnWindowDeactivate: false   // we close ourselves via onActiveChanged so the animation plays
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Dialog.NoBackground

    property bool editMode: false
    property string activeSubView: ""

    property var wifiNetworkList: []
    property var bluetoothDeviceList: []
    property alias contentWrapperRef: contentWrapper

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
    property var audioSinks: []
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
    signal connectWifi(string ssid)
    signal disconnectWifi()
    signal connectBluetooth(string mac)
    signal disconnectBluetooth(string mac)
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
        brightnessTileM, volumeTileM, brightnessTileS, volumeTileS, brightnessTileV, volumeTileV,
        dndTile, kdeConnectTile, perfTile, saverTile, micTile,
        muteTile, nightTile, clipTile, shotTile, kbdTile, airplaneTile, colorTile,
        connectivityTile
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
    }

    function closeWithAnim() {
        if (!dialogRoot.visible || _isClosing) return
            _isClosing = true
            editMode = false
            activeSubView = ""
            blur.update()
            closeDelayTimer.restart()
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
            activeSubView = ""
            resetTileStates()
            _isClosing = false
        } else {
            _isClosing = false
            repositionDialog()
            resetTileStates()
            requestActivate()
            dialogRoot.triggerCascades(true)
            Qt.callLater(() => repositionDialog())
        }
    }

    onActiveSubViewChanged: {
        blur.update()
        repositionDialog()
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
        repositionDialog()
        Qt.callLater(() => repositionDialog())
    }

    mainItem: FocusScope {
        id: container
        readonly property int shadowMargin: Math.max(48, dialogRoot.computedShadowSize + 24)
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

        Timer {
            id: closeDelayTimer
            interval: 1
            onTriggered: {
                dialogRoot.triggerCascades(false)
                dismissFinishTimer.interval = Math.round(300 / speedMultiplier) + Math.round(200 / speedMultiplier)
                dismissFinishTimer.restart()
            }
        }

        onWidthChanged: dialogRoot.repositionDialog()
        onHeightChanged: dialogRoot.repositionDialog()

        // Re-sync the blur region with the animating tiles on every frame while closing
        FrameAnimation {
            running: dialogRoot._isClosing && dialogRoot.visible
            onTriggered: dialogRoot.blur.update()
        }

        Loader {
            id: blurLoader
            active: dialogRoot.visible && dialogRoot.enableBlur
            sourceComponent: Component {
                BlurHelper {
                    window: dialogRoot
                    active: dialogRoot.visible && dialogRoot.enableBlur
                    tiles: (controlCenterDialog.activeSubView !== "" ? [] : [
                        powerTile, settingsTile, editTile, batteryTile, tileDrawer,
                        wifiTile, btTile, mediaTile, brightnessTile, volumeTile,
                        brightnessTileH, volumeTileH,
                        brightnessTileM, volumeTileM, brightnessTileS, volumeTileS, brightnessTileV, volumeTileV,
                        dndTile, kdeConnectTile, perfTile, saverTile, micTile,
                        muteTile, nightTile, clipTile, shotTile, kbdTile, airplaneTile, colorTile,
                        connectivityTile
                    ]).concat(
                        (controlCenterDialog.activeSubView === "wifi" || controlCenterDialog.activeSubView === "bluetooth") && typeof deviceSubView !== "undefined" && deviceSubView.activeTiles ? deviceSubView.activeTiles :
                        controlCenterDialog.activeSubView === "media" && typeof mediaSubView !== "undefined" && mediaSubView.activeTiles ? mediaSubView.activeTiles : []
                    )
                }
            }
        }

        // Clicks on the transparent margin around the popup (outside the tiles) close it
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.AllButtons
            onPressed: dialogRoot.closeWithAnim()
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                if (dialogRoot.activeSubView !== "") {
                    dialogRoot.activeSubView = ""
                    blur.update()
                } else if (dialogRoot.editMode) {
                    dialogRoot.editMode = false
                } else {
                    dialogRoot.closeWithAnim()
                }
                event.accepted = true
            }
        }

        Item {
            id: contentWrapper

            readonly property int contentPadding: 16
            property real drawerAnimProgress: dialogRoot.editMode ? 1.0 : 0.0
            Behavior on drawerAnimProgress {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutQuart
                }
            }

            // Drawer is split in two categories side by side: sliders (drawer cols 0-1) | tiles (drawer cols 2-3)
            readonly property real drawerInnerPad: 12
            readonly property real drawerSectionGap: 20
            readonly property real drawerSectionW: 2 * cellW + dialogRoot.tileSpacing
            readonly property real drawerWidth: drawerInnerPad * 2 + drawerSectionW * 2 + drawerSectionGap

            width: 336 + (contentPadding * 2) + ((drawerWidth + dialogRoot.tileSpacing) * drawerAnimProgress)
            height: {
                if (dialogRoot.activeSubView === "media") return Math.min(Screen.height * 0.9, mediaSubView.wantedHeight);
                if (dialogRoot.activeSubView === "wifi") return Math.min(Screen.height * 0.8, subViewHeight(wifiNetworkList.length));
                if (dialogRoot.activeSubView === "bluetooth") return Math.min(Screen.height * 0.8, subViewHeight(bluetoothDeviceList.length));
                return (contentPadding * 2) + headerRow.height + dialogRoot.tileSpacing + gridArea.height;
            }
            clip: true

            Behavior on height {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuart }
            }
            onHeightChanged: dialogRoot.repositionDialog()

            // Closing is driven by the per-tile dismiss cascade (reverse of the enter cascade).
            // The wrapper must NOT fade on close, otherwise the tiles vanish while the blur region stays.
            scale: dialogRoot.visible && !dialogRoot._isClosing ? 1.0 : 0.9
            opacity: dialogRoot.visible ? 1.0 : 0.0
            Behavior on scale {
                NumberAnimation {
                    duration: dialogRoot._isClosing
                    ? Math.round(300 / dialogRoot.speedMultiplier)
                    : Math.round(250 / dialogRoot.speedMultiplier)
                    easing.type: dialogRoot._isClosing ? Easing.InQuad : Easing.OutBack
                }
            }
            Behavior on opacity {
                enabled: !dialogRoot._isClosing
                NumberAnimation { duration: Math.round(200 / dialogRoot.speedMultiplier); easing.type: Easing.OutQuad }
            }

            transformOrigin: dialogRoot.isBottomLeft ? Item.BottomLeft : Item.BottomRight

            anchors.bottom: parent.bottom
            anchors.bottomMargin: container.shadowMargin
            anchors.left: parent.left
            anchors.leftMargin: container.shadowMargin

            // Swallows clicks on the popup's own background/gaps so they don't hit the
            // "click outside to close" area behind it
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.AllButtons
            }

            readonly property real cellW: Math.round((336 - 3 * dialogRoot.tileSpacing) / 4)
            readonly property real cellH: cellW

            // Exact height for DeviceSubView: outer padding (2*16) + inner margins (2*8)
            // + header (40) + column spacing (4) + list (n rows of 56 with 8 spacing)
            function subViewHeight(n) {
                let rows = Math.max(1, n)
                return (contentPadding * 2) + 16 + 40 + 4 + (rows * 56) + ((rows - 1) * 8)
            }

            function getGridX(c) { return Math.round(gridArea.x + c * (cellW + dialogRoot.tileSpacing)) }
            function getGridY(r) { return Math.round(gridArea.y + r * (cellH + dialogRoot.tileSpacing)) }
            function getGridW(sc) { return Math.round(sc * cellW + (sc - 1) * dialogRoot.tileSpacing) }
            function getGridH(sr) { return Math.round(sr * cellH + (sr - 1) * dialogRoot.tileSpacing) }
            function getDrawerX(c) { return Math.round(tileDrawer.x + drawerInnerPad + c * (cellW + dialogRoot.tileSpacing) + (c >= 2 ? drawerSectionGap : 0)) }
            function getDrawerY(r) { return Math.round(tileDrawer.y + 44 + r * (cellH + dialogRoot.tileSpacing)) }

            function updateDrawerLayout() {
                let drawerTiles = dialogRoot.allBentoTiles.filter(t => t && t.inDrawer)
                // 4 drawer columns: 0-1 = sliders, 2-3 = everything else
                let grid = []
                for (let i = 0; i < 60; i++) grid.push([false, false, false, false])

                    for (let i = 0; i < drawerTiles.length; i++) {
                        let t = drawerTiles[i]
                        let isSlider = t.sliderStyle !== undefined
                        let colStart = isSlider ? 0 : 2
                        let colEnd = colStart + 2
                        let placed = false
                        for (let r = 0; r < 50 && !placed; r++) {
                            for (let c = colStart; c < colEnd && !placed; c++) {
                                let free = true
                                for (let rr = 0; rr < t.spanRows; rr++) {
                                    for (let cc = 0; cc < t.spanCols; cc++) {
                                        if (c + cc >= colEnd || grid[r + rr][c + cc]) {
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

            // ================= MAIN VIEW =================
            Item {
                anchors.fill: parent
                visible: opacity > 0
                opacity: dialogRoot.activeSubView === "" ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                onOpacityChanged: blur.update()

                RowLayout {
                    id: headerRow
                    anchors.top: parent.top
                    anchors.topMargin: contentWrapper.contentPadding
                    anchors.left: parent.left
                    anchors.leftMargin: contentWrapper.contentPadding
                    anchors.right: parent.right
                    anchors.rightMargin: contentWrapper.contentPadding
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

                Item {
                    id: gridArea
                    anchors.top: headerRow.bottom
                    anchors.topMargin: dialogRoot.tileSpacing
                    anchors.left: parent.left
                    anchors.leftMargin: contentWrapper.contentPadding
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

                Kirigami.ShadowedRectangle {
                    id: tileDrawer
                    anchors.top: parent.top
                    anchors.topMargin: contentWrapper.contentPadding
                    anchors.left: gridArea.right
                    anchors.leftMargin: dialogRoot.tileSpacing
                    width: contentWrapper.drawerWidth
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
                        x: contentWrapper.drawerInnerPad
                        width: contentWrapper.drawerSectionW
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        horizontalAlignment: Text.AlignHCenter
                        text: "Sliders"
                        font.pixelSize: 11
                        font.bold: true
                        opacity: 0.7
                        color: dialogRoot.textColor
                    }

                    PlasmaComponents.Label {
                        x: contentWrapper.drawerInnerPad + contentWrapper.drawerSectionW + contentWrapper.drawerSectionGap
                        width: contentWrapper.drawerSectionW
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        horizontalAlignment: Text.AlignHCenter
                        text: "Tiles"
                        font.pixelSize: 11
                        font.bold: true
                        opacity: 0.7
                        color: dialogRoot.textColor
                    }

                    // divider between the two categories
                    Rectangle {
                        x: contentWrapper.drawerInnerPad + contentWrapper.drawerSectionW + (contentWrapper.drawerSectionGap - width) / 2
                        y: 40
                        width: 1
                        height: parent.height - 52
                        color: Qt.rgba(1, 1, 1, 0.18)
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

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton | Qt.MiddleButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                dialogRoot.activeSubView = "wifi"
                                blur.update()
                            } else if (mouse.button === Qt.MiddleButton) {
                                dialogRoot.closeWithAnim()
                            }
                        }
                        onWheel: (wheel) => {
                            if (!dialogRoot.editMode && wheel.angleDelta.y < 0) {
                                dialogRoot.activeSubView = "wifi"
                                blur.update()
                            }
                        }
                    }
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
                    subtitleText: {
                        if (!dialogRoot.btStatus) return "Off";
                        let connectedDev = dialogRoot.bluetoothDeviceList.find(d => d.connected);
                        return connectedDev ? connectedDev.name : "On";
                    }
                    iconSource: "preferences-system-bluetooth"
                    activeState: dialogRoot.btStatus
                    onTileClicked: dialogRoot.toggleBluetooth()

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton | Qt.MiddleButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                dialogRoot.activeSubView = "bluetooth"
                                blur.update()
                            } else if (mouse.button === Qt.MiddleButton) {
                                dialogRoot.closeWithAnim()
                            }
                        }
                    }
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

                BentoSliderTile {
                    id: brightnessTileM
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "brightness_mac"
                    inDrawer: true
                    spanCols: 2
                    spanRows: 1
                    sliderStyle: "mac"
                    titleText: "Display"
                    currentRatio: dialogRoot.brightnessRatio
                    iconSource: "brightness-high"
                    tooltipText: "Screen Brightness"
                    clampBottom: true
                    onRatioSet: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                    onRatioReleased: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                    Connections {
                        target: dialogRoot
                        function onBrightnessRatioChanged() {
                            if (!brightnessTileM.isSliderPressed && dialogRoot.brightnessRatio > 0) {
                                brightnessTileM.currentRatio = dialogRoot.brightnessRatio
                            }
                        }
                    }
                }

                BentoSliderTile {
                    id: volumeTileM
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "volume_mac"
                    inDrawer: true
                    spanCols: 2
                    spanRows: 1
                    sliderStyle: "mac"
                    titleText: "Sound"
                    currentRatio: dialogRoot.volumeRatio
                    iconSource: (dialogRoot.volumeRatio > 0.5) ? "audio-volume-high" : (dialogRoot.volumeRatio > 0.05) ? "audio-volume-medium" : "audio-volume-muted"
                    tooltipText: "Volume"
                    clampBottom: false
                    onRatioSet: (r) => dialogRoot.setVolumeRatio(r)
                    onRatioReleased: (r) => dialogRoot.setVolumeRatio(r)
                    Connections {
                        target: dialogRoot
                        function onVolumeRatioChanged() {
                            if (!volumeTileM.isSliderPressed && dialogRoot.volumeRatio >= 0) {
                                volumeTileM.currentRatio = dialogRoot.volumeRatio
                            }
                        }
                    }
                }

                BentoSliderTile {
                    id: brightnessTileS
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "brightness_slim"
                    inDrawer: true
                    spanCols: 2
                    spanRows: 1
                    sliderStyle: "slim"
                    titleText: "Display"
                    currentRatio: dialogRoot.brightnessRatio
                    iconSource: "brightness-high"
                    tooltipText: "Screen Brightness"
                    clampBottom: true
                    onRatioSet: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                    onRatioReleased: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                    Connections {
                        target: dialogRoot
                        function onBrightnessRatioChanged() {
                            if (!brightnessTileS.isSliderPressed && dialogRoot.brightnessRatio > 0) {
                                brightnessTileS.currentRatio = dialogRoot.brightnessRatio
                            }
                        }
                    }
                }

                BentoSliderTile {
                    id: volumeTileS
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "volume_slim"
                    inDrawer: true
                    spanCols: 2
                    spanRows: 1
                    sliderStyle: "slim"
                    titleText: "Sound"
                    currentRatio: dialogRoot.volumeRatio
                    iconSource: (dialogRoot.volumeRatio > 0.5) ? "audio-volume-high" : (dialogRoot.volumeRatio > 0.05) ? "audio-volume-medium" : "audio-volume-muted"
                    tooltipText: "Volume"
                    clampBottom: false
                    onRatioSet: (r) => dialogRoot.setVolumeRatio(r)
                    onRatioReleased: (r) => dialogRoot.setVolumeRatio(r)
                    Connections {
                        target: dialogRoot
                        function onVolumeRatioChanged() {
                            if (!volumeTileS.isSliderPressed && dialogRoot.volumeRatio >= 0) {
                                volumeTileS.currentRatio = dialogRoot.volumeRatio
                            }
                        }
                    }
                }

                BentoSliderTile {
                    id: brightnessTileV
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "brightness_slimv"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 2
                    sliderStyle: "slimV"
                    titleText: "Display"
                    currentRatio: dialogRoot.brightnessRatio
                    iconSource: "brightness-high"
                    tooltipText: "Screen Brightness"
                    clampBottom: true
                    onRatioSet: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                    onRatioReleased: (r) => dialogRoot.setBrightnessRatio(Math.round(r * 100))
                    Connections {
                        target: dialogRoot
                        function onBrightnessRatioChanged() {
                            if (!brightnessTileV.isSliderPressed && dialogRoot.brightnessRatio > 0) {
                                brightnessTileV.currentRatio = dialogRoot.brightnessRatio
                            }
                        }
                    }
                }

                BentoSliderTile {
                    id: volumeTileV
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "volume_slimv"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 2
                    sliderStyle: "slimV"
                    titleText: "Sound"
                    currentRatio: dialogRoot.volumeRatio
                    iconSource: (dialogRoot.volumeRatio > 0.5) ? "audio-volume-high" : (dialogRoot.volumeRatio > 0.05) ? "audio-volume-medium" : "audio-volume-muted"
                    tooltipText: "Volume"
                    clampBottom: false
                    onRatioSet: (r) => dialogRoot.setVolumeRatio(r)
                    onRatioReleased: (r) => dialogRoot.setVolumeRatio(r)
                    Connections {
                        target: dialogRoot
                        function onVolumeRatioChanged() {
                            if (!volumeTileV.isSliderPressed && dialogRoot.volumeRatio >= 0) {
                                volumeTileV.currentRatio = dialogRoot.volumeRatio
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
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Do Not Disturb"
                    subtitleText: dialogRoot.dndStatus ? "On" : "Off"
                    iconSource: "notifications-disabled"
                    activeState: dialogRoot.dndStatus
                    onTileClicked: dialogRoot.toggleDnd()
                }

                BentoToggleTile {
                    id: kdeConnectTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "kdeconnect"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "KDE Connect"
                    subtitleText: "Connected"
                    iconSource: "kdeconnect"
                    activeState: false
                    onTileClicked: dialogRoot.openKdeConnect()
                }

                BentoToggleTile {
                    id: perfTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "perf"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Performance"
                    subtitleText: dialogRoot.powerProfile
                    iconSource: "cpu"
                    activeState: dialogRoot.powerProfile === "performance"
                    onTileClicked: {
                        let next = dialogRoot.powerProfile === "balanced" ? "performance" : (dialogRoot.powerProfile === "performance" ? "power-saver" : "balanced")
                        dialogRoot.setPerformanceMode(next)
                    }
                }

                BentoToggleTile {
                    id: saverTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "saver"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Power Saver"
                    subtitleText: dialogRoot.powerProfile === "power-saver" ? "Active" : "Inactive"
                    iconSource: "battery-low"
                    activeState: dialogRoot.powerProfile === "power-saver"
                    onTileClicked: dialogRoot.setPerformanceMode(dialogRoot.powerProfile === "power-saver" ? "balanced" : "power-saver")
                }

                BentoToggleTile {
                    id: micTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "mic"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Microphone"
                    subtitleText: dialogRoot.micMuted ? "Muted" : "Active"
                    iconSource: dialogRoot.micMuted ? "microphone-sensitivity-muted" : "microphone-sensitivity-high"
                    activeState: !dialogRoot.micMuted
                    onTileClicked: dialogRoot.toggleMic()
                }

                BentoToggleTile {
                    id: muteTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "mute"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Audio Mute"
                    subtitleText: dialogRoot.audioMuted ? "Muted" : "Active"
                    iconSource: dialogRoot.audioMuted ? "audio-volume-muted" : "audio-volume-high"
                    activeState: !dialogRoot.audioMuted
                    onTileClicked: dialogRoot.toggleAudioMute()
                }

                BentoToggleTile {
                    id: nightTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "night"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Night Light"
                    subtitleText: dialogRoot.nightLightStatus ? "On" : "Off"
                    iconSource: "preferences-desktop-display-nightcolor"
                    activeState: dialogRoot.nightLightStatus
                    onTileClicked: dialogRoot.toggleNightLight()
                }

                BentoToggleTile {
                    id: clipTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "clipboard"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Clipboard"
                    subtitleText: "History"
                    iconSource: "edit-paste"
                    activeState: false
                    onTileClicked: dialogRoot.openClipboard()
                }

                BentoToggleTile {
                    id: shotTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "screenshot"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Screenshot"
                    subtitleText: "Capture"
                    iconSource: "spectacle"
                    activeState: false
                    onTileClicked: dialogRoot.openScreenshot()
                }

                BentoToggleTile {
                    id: kbdTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "kbd"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Keyboard Light"
                    subtitleText: dialogRoot.kbdLightStatus ? "On" : "Off"
                    iconSource: "input-keyboard"
                    activeState: dialogRoot.kbdLightStatus
                    onTileClicked: dialogRoot.toggleKbdBacklight()
                }

                BentoToggleTile {
                    id: airplaneTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "airplane"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Airplane Mode"
                    subtitleText: dialogRoot.airplaneStatus ? "On" : "Off"
                    iconSource: "network-flightmode"
                    activeState: dialogRoot.airplaneStatus
                    onTileClicked: dialogRoot.toggleAirplaneMode()
                }

                BentoToggleTile {
                    id: colorTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "color"
                    inDrawer: true
                    spanCols: 1
                    spanRows: 1
                    tileName: "Color Scheme"
                    subtitleText: "Customize"
                    iconSource: "applications-graphics"
                    activeState: false
                    onTileClicked: dialogRoot.openColorPicker()
                }

                BentoConnectivityTile {
                    id: connectivityTile
                    dialogRoot: dialogRoot
                    contentWrapper: contentWrapper
                    blurHelper: blur
                    tileKey: "connectivity"
                    inDrawer: true
                    spanCols: 2
                    spanRows: 2
                }
            }

            // ================= SUB-VIEW PANEL =================
            DeviceSubView {
                id: deviceSubView
                anchors.fill: parent
                anchors.margins: contentWrapper.contentPadding
                dialogRoot: dialogRoot
                blurHelper: blur
                isWifi: dialogRoot.activeSubView === "wifi"
            }
            MediaSubView {
                id: mediaSubView
                anchors.fill: parent
                dialogRoot: dialogRoot
                blurHelper: blur
            }
        }
    }
}
