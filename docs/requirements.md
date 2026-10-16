# Requirements

The product requirements as stated by the project owner. **This is the source of
truth.** If code or other docs conflict with this file, this file wins. Append new
requirements as they come in, with the date. Don't silently rewrite old ones; mark
them superseded instead.

## Product

| ID | Requirement | Since |
|----|-------------|-------|
| R1 | A **car infotainment system**. | 2026-10-17 |
| R2 | Runs **NixOS** on a **Raspberry Pi 5**. | 2026-10-17 |
| R3 | **Every app is a custom Nix flake** in its own repo. Apps **auto-fetch and rebuild when their repos update**. The owner is open to a better mechanism (we use the CI-gated pull model, see [updates.md](updates.md)). | 2026-10-17 |
| R4 | Audio leaves the Pi over **I2S** to a **custom DSP board**, which controls the car's sound system. | 2026-10-17 |
| R5 | **All features are onboard.** There is **no CarPlay and no Android Auto**, so don't add phone projection. | 2026-10-17 |
| R6 | Network access is through an **LTE modem**. | 2026-10-17 |
| R7 | Display is **HDMI**. Touch input comes from a **USB** touch controller (HID). | 2026-10-17 |
| R8 | The board is a **Raspberry Pi 5 with 8 GB RAM**. It has a **128 GB M.2 NVMe SSD** attached, which is where the system runs. A **16 GB microSD card** is available for flashing and recovery. | 2026-10-17 |

## Phase 1: base system (current)

| ID | Requirement | Status |
|----|-------------|--------|
| P1.1 | Basic NixOS repository for the Pi 5. | done, not yet booted on hardware |
| P1.2 | CI setup. | done |
| P1.3 | The OS boots straight into the UI. | done (cage kiosk) |
| P1.4 | The "desktop" shows a **big clock and date filling the left side** of the screen and a **drawer on the right**. | done (`shell/`) |
| P1.5 | A README with setup instructions. | done |
| P1.6 | Requirements and decisions are documented for future agents. | done (`CLAUDE.md`, `docs/`) |

## Not yet specified (ask the owner before assuming)

- DSP board protocol beyond I2S audio. For example: is there a control channel (I2C/SPI/UART) for volume and EQ? What sample rate and format?
- Which apps come first (media, navigation, radio, phone/Bluetooth calls, vehicle data/CAN?).
- Screen resolution and orientation. Touch controller model.
- The M.2 adapter model: an official/HAT+ board or a third-party adapter. This affects
  whether the EEPROM needs `PCIE_PROBE=1` to boot from NVMe.
- Power and ignition handling: how the Pi learns the ignition is off, and a safe-shutdown path.
- LTE modem model and APN. Data budget limits for updates.
- Locale, timezone and 12h/24h clock. Currently set to Europe/Amsterdam and 24h.
