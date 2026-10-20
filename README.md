
# Custom Grid Control Center Widget for KDE Plasma

A modern, highly customizable grid style Control Center plasmoid for KDE Plasma 6, featuring dynamic glassmorphism window blur, interactive media controls, system sliders, and a seamless one-click installer.

![KDE Plasma](https://img.shields.io/badge/KDE-Plasma_6-blue?style=flat-square&logo=kde)
![C++](https://img.shields.io/badge/C++-BlurHelper-orange?style=flat-square)

---
<img width="384" height="601" alt="Screenshot2" src="https://github.com/user-attachments/assets/7bba4f01-2d27-436e-bc44-dac476a52dbb" />

## ✨ Features

- **Custom Grid Layout**: A sleek, card-based interface inspired by modern design systems.
- **Dynamic C++ BlurHelper**: Smooth custom rounded-rectangle window background blur effects powered by `KWindowEffects`[cite: 1, 2].
- **Interactive Tiles**: 
  - 🎵 **Media Player Controls**: Track information, play/pause, and skip controls.
  - 🎚️ **Sliders**: Quick adjustments for audio volume and screen brightness.
  - ⚡ **Toggles**: Fast access to system states.
- **Universal Installer**: Zero-hassle setup script that automatically checks/installs dependencies (`cmake`, `extra-cmake-modules`, compilers) across Arch/CachyOS, Fedora, Ubuntu, openSUSE, and more.

---
<img width="367" height="513" alt="Screenshot1" src="https://github.com/user-attachments/assets/da2d3b9f-a776-44a9-bbde-8437bfb6d16b" />

## 🚀 Quick Installation

Clone or download the repository, then run the installer script:

```bash
git clone https://github.com/EvoModsX/KDE-Control-Center.git
cd "KDE-Control-Center"
chmod +x install.sh
./install.sh
