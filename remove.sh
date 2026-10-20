#!/bin/bash
set -e

# Change directory to script location
cd "$(dirname "$0")"

PLASMOID_ID="org.kde.controlcenter"
PLASMOID_FILE="${PLASMOID_ID}.plasmoid"
LOCAL_BLUR_PATH="${HOME}/.local/lib/qt6/qml/org/user/blurhelper"
SYS_BLUR_PATH="/usr/lib/qt6/qml/org/user/blurhelper"

echo "=========================================="
echo "  EvoMods Control Center Removal Script   "
echo "=========================================="

# 1. Uninstall Plasmoid widget via kpackagetool6
echo "--> Removing widget from Plasma..."
if kpackagetool6 --type Plasma/Applet --list | grep -q "${PLASMOID_ID}"; then
    kpackagetool6 --type Plasma/Applet --remove "${PLASMOID_ID}"
    echo "  [✓] Plasmoid widget uninstalled successfully."
else
    echo "  [-] Plasmoid widget was not found in Plasma."
fi

# 2. Remove generated packaging files locally
if [ -f "${PLASMOID_FILE}" ]; then
    echo "--> Removing local ${PLASMOID_FILE}..."
    rm -f "${PLASMOID_FILE}"
fi

# 3. Uninstall BlurHelper C++ QML module
echo "--> Uninstalling BlurHelper C++ module..."
REMOVED_BLUR=false

if [ -d "${LOCAL_BLUR_PATH}" ]; then
    rm -rf "${LOCAL_BLUR_PATH}"
    echo "  [✓] Removed local BlurHelper module from ~/.local/lib/qt6/qml"
    REMOVED_BLUR=true
fi

if [ -d "${SYS_BLUR_PATH}" ]; then
    read -p "System-wide BlurHelper detected in /usr/lib. Remove it with sudo? (y/N): " sys_choice
    case "$sys_choice" in
        y|Y )
            sudo rm -rf "${SYS_BLUR_PATH}"
            echo "  [✓] Removed system-wide BlurHelper module."
            REMOVED_BLUR=true
            ;;
        * )
            echo "  [-] Skipped system-wide BlurHelper removal."
            ;;
    esac
fi

if [ "$REMOVED_BLUR" = false ]; then
    echo "  [-] No installed BlurHelper module found."
fi

# 4. Clean local C++ build folder inside blurhelper/
if [ -d "blurhelper/build" ]; then
    echo "--> Cleaning local build artifacts..."
    rm -rf "blurhelper/build"
fi

# 5. Restart Plasmashell
read -p "--> Restart plasmashell now to apply changes? (y/N): " restart_choice
case "$restart_choice" in
    y|Y )
        echo "--> Restarting plasmashell..."
        plasmashell --replace & disown
        ;;
    * )
        echo "--> Removal complete! Remember to restart plasmashell manually."
        ;;
esac

echo "Done!"
