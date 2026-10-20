cmake_minimum_required(VERSION 3.20)
project(blurhelper)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQmlModule)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(KF6WindowSystem REQUIRED)

ecm_add_qml_module(blurhelper
    URI "org.user.blurhelper"
    VERSION 1.0
    GENERATE_PLUGIN_SOURCE
)

target_sources(blurhelper PRIVATE blurhelper.cpp blurhelper.h)
target_link_libraries(blurhelper PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick
    KF6::WindowSystem
)

ecm_finalize_qml_module(blurhelper)

# Explicitly install all plugin files into the org/user/blurhelper QML directory structure
install(TARGETS blurhelper DESTINATION ${KDE_INSTALL_QMLDIR}/org/user/blurhelper)
