# ❄️ AeroBar — Smart Air Conditioner macOS Menu Bar Remote

> Inspired by [Ilter Canberk's viral macOS status bar AC project](https://x.com/icanberk/status/2109031477484937571), **AeroBar** brings physical-remote-free climate control directly to your Mac's top menu bar with liquid glassmorphic styling, motorized vent mechanics, and dynamic flowing breeze animations.

---

## ✨ Features

- **Native macOS Menu Bar Agent (`LSUIElement`)**:
  - Resides quietly in the macOS status bar next to your clock and Control Center.
  - Live temperature readout (`21°`) and AC icon directly in your top bar.
  - Zero Dock clutter.
- **3D Isometric AC Unit & 60fps Fluttering Breeze**:
  - Motorized louver vent flap swings open when turned ON, and closes when turned OFF.
  - Multi-stream wave physics dynamically fluttering downwards.
  - Airflow colors dynamically shift to match your mode:
    - ❄️ **Cool**: Electric Cyan & Ice Blue
    - 🔥 **Heat**: Sunset Amber & Tangerine Glow
    - 🍃 **Eco Mode**: Emerald Mint
    - 💧 **Dry**: Lavender Violet
    - 💨 **Fan / Auto**: Crisp Arctic Silver
  - Airflow animation speed scales in real-time with **Fan Speed** (Quiet to Turbo).
- **Tactile Controls & Steppers**:
  - Bold temperature typography (`21°C` / `°F` toggleable in Settings).
  - Smooth custom slider track from `16°` to `32°`.
  - Minus `[-]` and Plus `[+]` stepping buttons.
  - Instant **Eco Mode** pill toggle switch.
- **4 Action Mode Cards**:
  - **Mode**: Cool, Heat, Auto, Dry, Fan
  - **Fan Speed**: Spinning fan blades at real-time RPM (Auto, Quiet, Low, Med, High, Turbo)
  - **Sleep**: Off, 30m, 1h, 2h, 4h, 8h with countdown
  - **Airflow**: Vertical, Horizontal, 3D Swing, Fixed
- **Authentic AC Remote Beep Sound**:
  - Built-in CoreAudio / Web Audio synthesizer generates authentic high-frequency remote chimes (`[pip!]` and `[pip-pip!]` on power).
- **Smart AC Integration & Brand Local / Cloud APIs**:
  - 🏠 **Samsung Local Network (LAN REST API)**: Direct zero-cloud local control over HTTPS on port 8888 with Bearer token authentication, self-signed TLS cert bypass, automatic local subnet port scanning, and port 8889 token handshake listener!
  - 🌟 **Samsung SmartThings (Cloud API)**: Direct cloud integration using your SmartThings Personal Access Token. Includes automatic device discovery, live room temperature telemetry, and command dispatch!
  - **Interactive Demo Mode** (ready out of the box with ambient room drift)
  - **Sensibo Cloud API** (API Key + Pod ID)
  - **Daikin Smart WiFi Controller** (Local LAN HTTP / BRP adapter)
  - **LG ThinQ OpenAPI**
  - **Tuya / Smart Life Cloud IoT**
- **Built-in Terminal CLI Controller**:
  - Full CLI interface via `./bin/samsung-ac-cli` or `AeroBar <command>`: query `status`, toggle `power on|off`, set `temp 22`, set `mode Cool`, `scan` subnet, and capture tokens via `listen-token`!

---

## ⬇️ Download & Install

Download the latest prebuilt release for macOS:

- 💿 **[Download AeroBar.dmg (v1.0.0)](https://github.com/faraz-scalepixel/Aerobar/releases/download/v1.0.0/AeroBar-v1.0.0.dmg)** *(Recommended — drag-and-drop installer)*
- 📦 **[Download AeroBar.zip (v1.0.0)](https://github.com/faraz-scalepixel/Aerobar/releases/download/v1.0.0/AeroBar-v1.0.0-macOS.zip)**
- 🏷️ **[View on GitHub Releases](https://github.com/faraz-scalepixel/Aerobar/releases/tag/v1.0.0)**

---

## 🚀 Quick Start (Native macOS App)

AeroBar has already been compiled into a standalone macOS bundle: [`AeroBar.app`](file:///Users/faraz/Apps/AirCon%20Remote/AeroBar.app).

To launch it immediately into your MacBook top bar:

```bash
./run.sh
```

Or open directly:

```bash
open AeroBar.app
```

### To rebuild at any time:

```bash
./build.sh
```

---

## 💻 CLI Controller (Local Samsung AC)

AeroBar includes a terminal CLI to test and control your Samsung Smart AC directly over your local network:

```bash
# Scan local subnet for Samsung ACs on port 8888
./bin/samsung-ac-cli scan

# Check device status (power, room temp, target temp, mode)
AC_IP=192.168.1.100 AC_TOKEN=your_token ./bin/samsung-ac-cli status

# Turn power ON or OFF
./bin/samsung-ac-cli --ip 192.168.1.100 --token your_token power on

# Set target temperature
./bin/samsung-ac-cli --ip 192.168.1.100 --token your_token temp 22

# Set operational mode (Cool, Wind, Auto, Dry, Heat)
./bin/samsung-ac-cli --ip 192.168.1.100 --token your_token mode Cool

# Start background listener on port 8889 to capture initial AC token handshake
./bin/samsung-ac-cli listen-token
```

---

If you want to preview and test the UI in your web browser:

1. The local server is running at:
   **[http://localhost:4173](http://localhost:4173)**
2. Or simply open [`web/index.html`](file:///Users/faraz/Apps/AirCon%20Remote/web/index.html) in Safari / Chrome:
   ```bash
   open web/index.html
   ```

---

## 📁 Repository Structure

```
AirCon Remote/
├── AeroBar.app/                      # Compiled native macOS application bundle
├── Sources/AeroBar/
│   ├── AppDelegate.swift             # NSStatusItem & NSPopover lifecycle manager
│   ├── main.swift                    # App entry point
│   ├── Models/
│   │   └── ACState.swift             # Central state machine & ambient room simulation
│   ├── Services/
│   │   ├── SoundManager.swift        # CoreAudio AC beep synthesizer
│   │   └── SmartACService.swift      # Sensibo, Daikin, LG ThinQ, Tuya cloud connectors
│   ├── Views/
│   │   ├── MenuBarView.swift         # Glassmorphic popover container
│   │   ├── ACUnitView.swift          # 3D isometric AC unit & 60fps breeze waves
│   │   ├── TemperatureSlider.swift   # Custom slider track & steppers
│   │   ├── FeatureCardView.swift     # 4 action mode cards & animated spinning fan
│   │   └── SettingsView.swift        # Brand Cloud API configuration sheet
│   └── Resources/
│       └── AppIcon.png               # Custom AeroBar app icon
├── web/
│   ├── index.html                    # Interactive Web Simulator HTML
│   ├── style.css                     # Glassmorphic CSS design system
│   └── app.js                        # 60fps Canvas breeze & Web Audio engine
├── build.sh                          # One-click compile & packaging script
├── run.sh                            # One-click launch script
└── Package.swift                     # Swift Package configuration
```
