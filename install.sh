#!/bin/bash
set -e

cd "$(dirname "$0")"

PLASMOID_ID="org.kde.controlcenter"
PLASMOID_FILE="${PLASMOID_ID}.plasmoid"
LOCAL_QML_PATH="${HOME}/.local/lib/qt6/qml"
echo " "
echo "=========================================="
echo "  EvoMods Control Center Installer Script  "
echo "=========================================="
echo " "
# 1. Package into .plasmoid
echo "--> Packaging widget into ${PLASMOID_FILE}..."
rm -f "${PLASMOID_FILE}"

if [ -d "${PLASMOID_ID}" ]; then
    zip -q -r "${PLASMOID_FILE}" "${PLASMOID_ID}/" -x "*.git*" "*/blurhelper/build/*" "*.plasmoid" "install.sh" "remove.sh"
elif [ -f "metadata.json" ] && [ -d "contents" ]; then
    zip -q -r "${PLASMOID_FILE}" metadata.json contents/ -x "*.git*" "*/blurhelper/build/*"
else
    echo "Error: Could not find ${PLASMOID_ID}/ folder or metadata.json!"
    exit 1
fi

# 2. Install or upgrade plasmoid via kpackagetool6
echo "--> Installing widget to Plasma..."
if kpackagetool6 --type Plasma/Applet --list | grep -q "${PLASMOID_ID}"; then
    kpackagetool6 --type Plasma/Applet --upgrade "${PLASMOID_FILE}"
else
    kpackagetool6 --type Plasma/Applet --install "${PLASMOID_FILE}"
fi

# 3. Locate & Build BlurHelper C++ Module
BLUR_PATH=""
if [ -d "blurhelper" ]; then
    BLUR_PATH="blurhelper"
elif [ -d "src/blurhelper" ]; then
    BLUR_PATH="src/blurhelper"
elif [ -d "org.kde.controlcenter/contents/ui/blurhelper" ]; then
    BLUR_PATH="org.kde.controlcenter/contents/ui/blurhelper"
fi

if [ -n "${BLUR_PATH}" ]; then
    echo "--> Compiling BlurHelper from ${BLUR_PATH}..."
    rm -rf "${BLUR_PATH}/build"
    mkdir -p "${BLUR_PATH}/build"
    cd "${BLUR_PATH}/build"

    cmake .. -DCMAKE_INSTALL_PREFIX="${HOME}/.local" -DKDE_INSTALL_QMLDIR="lib/qt6/qml" > /dev/null 2>&1
    make -j$(nproc) > /dev/null 2>&1
    make install > /dev/null 2>&1

    # Guarantee deployment of module files to ~/.local/lib/qt6/qml/org/user/blurhelper
    TARGET_DIR="${LOCAL_QML_PATH}/org/user/blurhelper"
    mkdir -p "${TARGET_DIR}"
    cp -rf bin/org/user/blurhelper/* "${TARGET_DIR}/" 2>/dev/null || true

    cd - > /dev/null
    rm -rf "${BLUR_PATH}/build"
    echo "  [✓] BlurHelper successfully built and installed!"
fi

# 4. Permanently register local QML path for systemd / Plasma user session
echo "--> Configuring system environment for user QML modules..."
mkdir -p "${HOME}/.config/environment.d"
CONF_FILE="${HOME}/.config/environment.d/qml.conf"
if ! grep -q "QML2_IMPORT_PATH" "${CONF_FILE}" 2>/dev/null; then
    echo "QML2_IMPORT_PATH=${LOCAL_QML_PATH}:${HOME}/.local/lib64/qt6/qml:\${QML2_IMPORT_PATH}" >> "${CONF_FILE}"
fi

# 5. Refresh Plasmashell with explicit import environment
echo "--> Restarting plasmashell to apply changes..."
export QML2_IMPORT_PATH="${LOCAL_QML_PATH}:${HOME}/.local/lib64/qt6/qml:${QML2_IMPORT_PATH}"
plasmashell --replace & disown

echo " "
echo "=========================================="
echo "      Installation Complete! Enjoy!  "
echo "=========================================="
echo " "
