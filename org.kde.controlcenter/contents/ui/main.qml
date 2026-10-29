import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.volume as PulseAudio

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    compactRepresentation: MouseArea {
        id: compactRoot
        implicitWidth: Kirigami.Units.iconSizes.smallMedium
        implicitHeight: Kirigami.Units.iconSizes.smallMedium
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (controlCenterDialog.visible) controlCenterDialog.closeWithAnim()
                else controlCenterDialog.visible = true
        }
        Kirigami.Icon { anchors.centerIn: parent; width: parent.implicitWidth; height: width; source: "configure" }
    }

    fullRepresentation: Item { implicitWidth: 0; implicitHeight: 0 }

    PulseAudio.SinkModel { id: paSinkModel }
    readonly property var defaultSink: (paSinkModel.preferredSink !== undefined) ? paSinkModel.preferredSink : paSinkModel.defaultSink
    property real systemVolRatio: 0.5
    readonly property real effectiveVolRatio: (defaultSink && defaultSink.volume !== undefined) ? Math.max(0, Math.min(1.0, defaultSink.volume / 65536)) : systemVolRatio

    property string mediaTitle: "Not playing"
    property string mediaArtist: ""
    property string mediaStatus: "Stopped"
    property string mediaArtUrl: ""
    property real mediaPosition: 0
    property real mediaLength: 0

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
    property real currentBrightnessRatio: 0.8
    property bool kbdLightStatus: false
    property bool airplaneStatus: !root.wifiStatus && !root.btStatus

    property var wifiNetworks: []
    property var bluetoothDevices: []
    property var audioSinks: []

    readonly property string batteryCapCmd: "sh -c 'cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo 100'"
    readonly property string batteryStatCmd: "sh -c 'cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo Discharging'"
    readonly property string kbdLightGetCmd: "brightnessctl --device='*kbd_backlight*' g 2>/dev/null || echo 0"

    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            let out = data.stdout.trim()
            if (sourceName.indexOf("nmcli radio wifi") !== -1) {
                let parts = out.split(":")
                wifiStatus = (parts[0] === "enabled")
                wifiSsid = parts.slice(1).join(":")
            } else if (sourceName === "bluetoothctl show") {
                btStatus = out.includes("Powered: yes")
            } else if (sourceName.indexOf("nmcli -t -f active,ssid,signal dev wifi") !== -1) {
                let netMap = {}
                let lines = out.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(":")
                    if (parts.length >= 2 && parts[1].trim() !== "") {
                        let ssid = parts[1].trim()
                        let active = parts[0] === "yes"
                        let strength = parseInt(parts[2]) || 50
                        if (!netMap[ssid] || strength > netMap[ssid].strength) {
                            netMap[ssid] = { ssid: ssid, active: active, strength: strength }
                        }
                        if (active) netMap[ssid].active = true
                    }
                }
                let nets = []
                for (let k in netMap) nets.push(netMap[k])
                    nets.sort((a, b) => b.strength - a.strength)
                    wifiNetworks = nets
            } else if (sourceName.indexOf("bluetoothctl devices") !== -1) {
                let devs = []
                let lines = out.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim()
                    if (line.startsWith("Device")) {
                        let parts = line.split(" ")
                        let mac = parts[1]
                        let name = parts.slice(2).join(" ")
                        if (name && name !== "(public)") {
                            let existing = bluetoothDevices.find(d => d.mac === mac)
                            let connected = existing ? existing.connected : false
                            devs.push({ name: name, mac: mac, connected: connected })
                        }
                    }
                }
                if (devs.length > 0) bluetoothDevices = devs
            } else if (sourceName.indexOf("bluetoothctl info") !== -1) {
                let macMatch = sourceName.match(/bluetoothctl info ([0-9A-F:]+)/i)
                if (macMatch && macMatch[1]) {
                    let mac = macMatch[1]
                    let connected = out.includes("Connected: yes")
                    let updated = bluetoothDevices.map(d => {
                        if (d.mac === mac) {
                            return { name: d.name, mac: d.mac, connected: connected }
                        }
                        return d
                    })
                    bluetoothDevices = updated
                }
            } else if (sourceName.indexOf("pactl list sinks") !== -1) {
                let sinks = []
                let blocks = out.split("Sink #")
                let defaultSinkName = root.defaultSink ? root.defaultSink.name : ""
                for (let i = 1; i < blocks.length; i++) {
                    let block = blocks[i]
                    let nameMatch = block.match(/Name:\s+([^\n]+)/)
                    let descMatch = block.match(/Description:\s+([^\n]+)/)
                    if (nameMatch && nameMatch[1]) {
                        let name = nameMatch[1].trim()
                        let description = descMatch ? descMatch[1].trim() : name
                        let active = (name === defaultSinkName)
                        sinks.push({ name: name, description: description, active: active })
                    }
                }
                audioSinks = sinks
            } else if (sourceName.indexOf("kreadconfig6 --file plasmanotifyrc") !== -1) {
                dndStatus = out === "true"
            } else if (sourceName === "powerprofilesctl get") {
                powerProfile = out
            } else if (sourceName.indexOf("get-source-mute") !== -1) {
                micMuted = out.indexOf("yes") !== -1
            } else if (sourceName.indexOf("get-sink-mute") !== -1) {
                audioMuted = out.indexOf("yes") !== -1
            } else if (sourceName === root.batteryCapCmd) {
                let val = parseInt(out); if (!isNaN(val)) batteryPercent = Math.max(0, Math.min(100, val))
            } else if (sourceName === root.batteryStatCmd) {
                batteryCharging = (out === "Charging" || out === "Full")
            } else if (out.startsWith("bright:")) {
                let parts = out.replace("bright:", "").split(":")
                if (parts.length === 2 && parts[0] && parts[1]) {
                    let cur = parseInt(parts[0])
                    let max = parseInt(parts[1])
                    if (!isNaN(cur) && !isNaN(max) && max > 0) {
                        currentBrightnessRatio = Math.max(0.05, Math.min(1.0, cur / max))
                    }
                }
            } else if (out.startsWith("kbd:")) {
                let val = parseInt(out.replace("kbd:", ""))
                kbdLightStatus = (!isNaN(val) && val > 0)
            } else if (sourceName.indexOf("playerctl metadata") !== -1) {
                if (out.length > 0) {
                    let parts = out.split(" -::- ")
                    mediaTitle = parts[0] || "Unknown Title"
                    mediaArtist = parts[1] || ""
                    mediaArtUrl = parts[2] || ""
                    let lenStr = parts[3]
                    if (lenStr) {
                        let lenUs = parseInt(lenStr)
                        if (!isNaN(lenUs)) mediaLength = lenUs / 1000000.0
                            else mediaLength = 0
                    } else { mediaLength = 0 }
                } else { mediaTitle = "Not playing"; mediaArtist = ""; mediaArtUrl = ""; mediaLength = 0 }
            } else if (sourceName.indexOf("playerctl position") !== -1) {
                let val = parseFloat(out)
                if (!isNaN(val)) mediaPosition = val
            } else if (sourceName === "playerctl status") {
                mediaStatus = out
            }
            disconnectSource(sourceName)
        }

        function run(cmd) { connectSource(cmd) }
    }

    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            execSource.run("sh -c 'r=$(nmcli radio wifi); if [ \"$r\" = \"enabled\" ]; then s=$(nmcli -t -f active,ssid dev wifi | grep \"^yes\" | cut -d: -f2); echo \"enabled:${s}\"; else echo \"disabled:\"; fi'")
            execSource.run("bluetoothctl show")
            execSource.run("nmcli -t -f active,ssid,signal dev wifi")
            execSource.run("bluetoothctl devices")
            execSource.run("sh -c 'bluetoothctl devices | while read -r type mac name; do [ -n \"$mac\" ] && bluetoothctl info \"$mac\"; done'")
            execSource.run("pactl list sinks")
            execSource.run("sh -c 'kreadconfig6 --file plasmanotifyrc --group Notifications --key DoNotDisturb 2>/dev/null || echo false'")
            execSource.run("powerprofilesctl get")
            execSource.run("pactl get-source-mute @DEFAULT_SOURCE@")
            execSource.run("pactl get-sink-mute @DEFAULT_SINK@")
            execSource.run(root.batteryCapCmd)
            execSource.run(root.batteryStatCmd)
            execSource.run("sh -c 'm=$(qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightnessMax 2>/dev/null); c=$(qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightness 2>/dev/null); if [ -n \"$m\" ] && [ -n \"$c\" ]; then echo \"bright:${c}:${m}\"; else c2=$(brightnessctl -c backlight g 2>/dev/null); m2=$(brightnessctl -c backlight m 2>/dev/null); echo \"bright:${c2}:${m2}\"; fi'")
            execSource.run("sh -c 'b=$(qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/KeyboardBrightnessControl org.kde.Solid.PowerManagement.Actions.KeyboardBrightnessControl.keyboardBrightness 2>/dev/null); if [ -n \"$b\" ] && [ \"$b\" != \"0\" ]; then echo \"kbd:$b\"; else b2=$(brightnessctl -d \"*kbd*\" g 2>/dev/null); echo \"kbd:$b2\"; fi'")

            execSource.run("playerctl status")
            execSource.run("playerctl metadata --format '{{title}} -::- {{artist}} -::- {{mpris:artUrl}} -::- {{mpris:length}}' 2>/dev/null")
            execSource.run("playerctl position 2>/dev/null")
        }
    }

    ControlCenterPopup {
        id: controlCenterDialog
        visualParent: compactRoot
        wifiStatus: root.wifiStatus
        wifiSsid: root.wifiSsid
        btStatus: root.btStatus
        dndStatus: root.dndStatus
        micMuted: root.micMuted
        audioMuted: root.audioMuted
        powerProfile: root.powerProfile
        nightLightStatus: root.nightLightStatus
        batteryPercent: root.batteryPercent
        batteryCharging: root.batteryCharging
        brightnessRatio: root.currentBrightnessRatio
        volumeRatio: root.effectiveVolRatio
        kbdLightStatus: root.kbdLightStatus
        airplaneStatus: root.airplaneStatus
        defaultSink: root.defaultSink

            wifiNetworkList: root.wifiNetworks
            bluetoothDeviceList: root.bluetoothDevices
            audioSinks: root.audioSinks

            mediaTitle: root.mediaTitle
            mediaArtist: root.mediaArtist
            mediaStatus: root.mediaStatus
            mediaArtUrl: root.mediaArtUrl
            mediaPosition: root.mediaPosition
            mediaLength: root.mediaLength

            onRunCommand: (cmd) => execSource.run(cmd)

            onSetVolumeRatio: (ratio) => {
                root.systemVolRatio = ratio
                if (root.defaultSink && root.defaultSink.volume !== undefined) root.defaultSink.volume = Math.round(ratio * 65536)
                    let pct = Math.round(ratio * 100)
                    execSource.run("pactl set-sink-volume @DEFAULT_SINK@ " + pct + "% 2>/dev/null")
            }

            onSetBrightnessRatio: (pct) => {
                root.currentBrightnessRatio = pct / 100.0
                execSource.run("sh -c 'm=$(qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightnessMax 2>/dev/null); if [ -n \"$m\" ]; then v=$(( " + pct + " * m / 100 )); qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.setBrightness $v; else brightnessctl -c backlight s " + pct + "% 2>/dev/null; fi'")
            }

            onToggleWifi: { execSource.run("nmcli radio wifi " + (!root.wifiStatus ? "on" : "off")); root.wifiStatus = !root.wifiStatus }
            onToggleBluetooth: { execSource.run("bluetoothctl " + (!root.btStatus ? "power on" : "power off")); root.btStatus = !root.btStatus }

            onConnectWifi: (ssid) => execSource.run("nmcli device wifi connect '" + ssid + "'")
            onDisconnectWifi: execSource.run("nmcli device disconnect wlan0 2>/dev/null || nmcli device disconnect wifi 2>/dev/null")

            onConnectBluetooth: (mac) => {
                execSource.run("bluetoothctl connect " + mac)
                execSource.run("bluetoothctl info " + mac)
            }
            onDisconnectBluetooth: (mac) => {
                execSource.run("bluetoothctl disconnect " + mac)
                execSource.run("bluetoothctl info " + mac)
            }

            onToggleDnd: {
                let next = !root.dndStatus
                root.dndStatus = next
                execSource.run("sh -c 'kwriteconfig6 --file plasmanotifyrc --group Notifications --key DoNotDisturb " + next + " && qdbus6 org.freedesktop.Notifications /org/freedesktop/Notifications org.kde.PlasmaNotifications.reparseConfiguration'")
            }

            onToggleMic: { execSource.run("pactl set-source-mute @DEFAULT_SOURCE@ toggle"); root.micMuted = !root.micMuted }
            onToggleAudioMute: { execSource.run("pactl set-sink-mute @DEFAULT_SINK@ toggle"); root.audioMuted = !root.audioMuted }
            onSetPerformanceMode: (mode) => { execSource.run("powerprofilesctl set " + mode); root.powerProfile = mode }
            onToggleNightLight: {
                root.nightLightStatus = !root.nightLightStatus
                execSource.run("qdbus6 org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightLightEnabled " + root.nightLightStatus + " 2>/dev/null")
            }

            onToggleKbdBacklight: {
                let next = !root.kbdLightStatus
                root.kbdLightStatus = next
                let action = next ? "100%" : "0%"
                execSource.run("sh -c 'm=$(qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/KeyboardBrightnessControl org.kde.Solid.PowerManagement.Actions.KeyboardBrightnessControl.keyboardBrightnessMax 2>/dev/null); if [ -n \"$m\" ]; then qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/KeyboardBrightnessControl org.kde.Solid.PowerManagement.Actions.KeyboardBrightnessControl.setKeyboardBrightness " + (next ? "$m" : "0") + "; else brightnessctl -d \"*kbd*\" s " + action + " 2>/dev/null; fi'")
            }

            onToggleAirplaneMode: {
                let turnOnAirplane = root.wifiStatus || root.btStatus
                if (turnOnAirplane) {
                    execSource.run("nmcli radio wifi off; bluetoothctl power off")
                    root.wifiStatus = false; root.btStatus = false
                } else {
                    execSource.run("nmcli radio wifi on; bluetoothctl power on")
                    root.wifiStatus = true; root.btStatus = true
                }
            }

            onOpenClipboard: execSource.run("qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.showContextMenu 2>/dev/null || qdbus org.kde.klipper /klipper org.kde.klipper.klipper.showContextMenu 2>/dev/null")
            onOpenScreenshot: execSource.run("spectacle &")
            onOpenKdeConnect: execSource.run("kdeconnect-app &")
            onOpenColorPicker: execSource.run("qdbus6 org.kde.KWin /ColorPicker org.kde.kwin.ColorPicker.pick")
            onOpenPowerMenu: execSource.run("qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptAll 2>/dev/null || qdbus org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptAll 2>/dev/null || plasma-session-logout")
            onOpenSettings: execSource.run("systemsettings &")
    }
}
