import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import org.kde.plasma.components as PlasmaComponents

Kirigami.ScrollablePage {
    id: page

    // --- Property Bindings ---
    property alias cfg_enableBlur: blurCheck.checked
    property alias cfg_tileFillMode: fillModeCombo.currentIndex
    property alias cfg_iconScale: iconScaleSlider.value
    property alias cfg_tileColor: colorButton.color
    property alias cfg_tileAlpha: alphaSlider.value
    property alias cfg_activeTileColor: activeTileColorButton.color
    property alias cfg_activeIconColor: activeIconColorButton.color
    property alias cfg_inactiveIconColor: inactiveIconColorButton.color
    property alias cfg_textColor: textColorButton.color

    property alias cfg_uiScale: scaleSlider.value
    property alias cfg_popupPosition: positionCombo.currentIndex
    property alias cfg_tileRadius: radiusSpin.value
    property alias cfg_roundSmallTiles: roundSmallTilesCheck.checked
    property alias cfg_tileSpacing: spacingSpin.value
    property alias cfg_edgeMargin: marginSpin.value
    property alias cfg_panelHeightOffset: offsetSpin.value

    property alias cfg_showBorder: borderCheck.checked
    property alias cfg_borderColor: borderColorButton.color
    property alias cfg_borderAlpha: borderAlphaSlider.value
    property alias cfg_borderWidth: borderWidthSpin.value

    property alias cfg_showShadow: shadowCheck.checked
    property alias cfg_shadowColor: shadowColorButton.color
    property alias cfg_shadowAlpha: shadowAlphaSlider.value
    property alias cfg_shadowSize: shadowSizeSpin.value
    property alias cfg_shadowSmoothing: shadowSmoothingSpin.value

    property alias cfg_animStyle: animStyleCombo.currentIndex
    property alias cfg_animSpeed: speedSlider.value

    Kirigami.FormLayout {
        anchors.fill: parent

        // ==========================================
        // SECTION 1: THEME & APPEARANCE
        // ==========================================
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Theme & Appearance") }

        QQC2.CheckBox {
            id: blurCheck
            Kirigami.FormData.label: i18n("Background blur:")
            text: i18n("Enable frosted-glass blur behind tiles")
        }

        QQC2.ComboBox {
            id: fillModeCombo
            Kirigami.FormData.label: i18n("Activation style:")
            model: [
                i18n("Rounded Icon Pill (Default)"),
                i18n("Full Tile Fill")
            ]
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Icon scale:")
            QQC2.Slider {
                id: iconScaleSlider
                from: 0.60
                to: 1.80
                stepSize: 0.05
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: Math.round(iconScaleSlider.value * 100) + "%"
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background opacity:")
            QQC2.Slider {
                id: alphaSlider
                from: 0.05
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: Math.round(alphaSlider.value * 100) + "%"
            }
        }

        Kirigami.Separator { Kirigami.FormData.isSection: false }

        // ==========================================
        // SECTION 2: COLOR PALETTE
        // ==========================================
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Color Palette") }

        KQuickControls.ColorButton {
            id: colorButton
            Kirigami.FormData.label: i18n("Tile background:")
            showAlphaChannel: false
        }

        KQuickControls.ColorButton {
            id: activeTileColorButton
            Kirigami.FormData.label: i18n("Active accent color:")
            showAlphaChannel: false
        }

        KQuickControls.ColorButton {
            id: activeIconColorButton
            Kirigami.FormData.label: i18n("Active icon color:")
            showAlphaChannel: false
        }

        KQuickControls.ColorButton {
            id: inactiveIconColorButton
            Kirigami.FormData.label: i18n("Inactive icon color:")
            showAlphaChannel: false
        }

        KQuickControls.ColorButton {
            id: textColorButton
            Kirigami.FormData.label: i18n("Text color:")
            showAlphaChannel: false
        }

        Kirigami.Separator { Kirigami.FormData.isSection: false }

        // ==========================================
        // SECTION 3: LAYOUT & SIZING
        // ==========================================
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Layout & Metrics") }

        RowLayout {
            Kirigami.FormData.label: i18n("Overall UI scale:")
            QQC2.Slider {
                id: scaleSlider
                from: 0.70
                to: 1.60
                stepSize: 0.05
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: Math.round(scaleSlider.value * 100) + "%"
            }
        }

        QQC2.ComboBox {
            id: positionCombo
            Kirigami.FormData.label: i18n("Screen position:")
            model: [i18n("Bottom Right"), i18n("Bottom Left")]
        }

        QQC2.SpinBox {
            id: radiusSpin
            Kirigami.FormData.label: i18n("Corner radius (px):")
            from: 8
            to: 36
        }

        QQC2.CheckBox {
            id: roundSmallTilesCheck
            Kirigami.FormData.label: i18n("Rounded small tiles:")
            text: i18n("Force 36px radius for 1x1 and 2x1 tiles")
        }

        QQC2.SpinBox {
            id: spacingSpin
            Kirigami.FormData.label: i18n("Tile spacing (px):")
            from: 4
            to: 36
        }

        QQC2.SpinBox {
            id: marginSpin
            Kirigami.FormData.label: i18n("Screen edge margin (px):")
            from: 0
            to: 100
        }

        QQC2.SpinBox {
            id: offsetSpin
            Kirigami.FormData.label: i18n("Taskbar offset (px):")
            from: 0
            to: 120
        }

        Kirigami.Separator { Kirigami.FormData.isSection: false }

        // ==========================================
        // SECTION 4: OUTLINES & BORDERS
        // ==========================================
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Outlines & Borders") }

        QQC2.CheckBox {
            id: borderCheck
            Kirigami.FormData.label: i18n("Enable outlines:")
            text: i18n("Show outline around tiles")
        }

        KQuickControls.ColorButton {
            id: borderColorButton
            Kirigami.FormData.label: i18n("Outline color:")
            visible: borderCheck.checked
            showAlphaChannel: false
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Outline opacity:")
            visible: borderCheck.checked
            QQC2.Slider {
                id: borderAlphaSlider
                from: 0.05
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: Math.round(borderAlphaSlider.value * 100) + "%"
            }
        }

        QQC2.SpinBox {
            id: borderWidthSpin
            Kirigami.FormData.label: i18n("Thickness (px):")
            visible: borderCheck.checked
            from: 1
            to: 4
        }

        Kirigami.Separator { Kirigami.FormData.isSection: false }

        // ==========================================
        // SECTION 5: SHADOWS & GLOW
        // ==========================================
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Shadows & Glow") }

        QQC2.CheckBox {
            id: shadowCheck
            Kirigami.FormData.label: i18n("Enable shadows:")
            text: i18n("Draw soft shadows around tiles")
        }

        KQuickControls.ColorButton {
            id: shadowColorButton
            Kirigami.FormData.label: i18n("Shadow color:")
            visible: shadowCheck.checked
            showAlphaChannel: false
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Shadow opacity:")
            visible: shadowCheck.checked
            QQC2.Slider {
                id: shadowAlphaSlider
                from: 0.05
                to: 1.0
                stepSize: 0.05
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: Math.round(shadowAlphaSlider.value * 100) + "%"
            }
        }

        QQC2.SpinBox {
            id: shadowSizeSpin
            Kirigami.FormData.label: i18n("Spread size (px):")
            visible: shadowCheck.checked
            from: 2
            to: 60
        }

        QQC2.SpinBox {
            id: shadowSmoothingSpin
            Kirigami.FormData.label: i18n("Smoothing size (px):")
            visible: shadowCheck.checked
            from: 0
            to: 40
        }

        Kirigami.Separator { Kirigami.FormData.isSection: false }

        // ==========================================
        // SECTION 6: ANIMATIONS
        // ==========================================
        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: i18n("Animations") }

        QQC2.ComboBox {
            id: animStyleCombo
            Kirigami.FormData.label: i18n("Animation style:")
            model: [
                i18n("Elastic Bounce (Default)"),
                i18n("Smooth Scale"),
                i18n("Fade Only (Fast & Lightweight)")
            ]
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Animation speed:")
            QQC2.Slider {
                id: speedSlider
                from: 0.5
                to: 2.5
                stepSize: 0.1
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: speedSlider.value.toFixed(1) + "x"
            }
        }
    }
}
