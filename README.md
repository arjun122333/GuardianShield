# 🛡️ Guardian Shield — Personal Safety & Emergency Mobile App

Guardian Shield is a personal safety mobile application built with **Flutter (Dart)** and **Firebase**. It provides silent emergency triggers, hidden segmented video recording, interactive disguise modes (e.g. functioning calculator decoy), live GPS tracking, and automated SMS/Calling dispatch to trusted guardians.

---

## 📱 Features

1. **Silent Emergency Trigger System**
   - Central animated **Hold-to-Activate Panic Button** (1.2s debounce).
   - **Triple-Shake Detection (3x)** using device accelerometer.
   - Volume key rapid-press trigger support.
   - Zero shutter sounds, no flashes, completely silent activation.

2. **Decoy Disguise Modes**
   - **Fake Calculator:** Fully functioning mathematical calculator. Hides active emergency recording in the background. Entering your secret PIN followed by `=` (e.g. `9119=`) unlocks the safety master dialog.
   - **Fake Low Battery & Black AMOLED Screen modes.**

3. **Live GPS Tracking**
   - Captures high-accuracy GPS coordinates immediately upon trigger.
   - Generates formatted Google Maps live links (`https://maps.google.com/?q=lat,lng`).
   - Streams periodic location breadcrumbs every 30 seconds.

4. **Automated SMS & Calling Dispatch**
   - Broadcasts emergency SMS alert with live location to up to 5 guardians.
   - Auto-dials primary guardian after a 10-second countdown.

5. **Encrypted Evidence Vault**
   - Segmented 60-second video recording chunks.
   - Encrypted with user's AES-256 master key.
   - Legal evidence package exporter.

---

## 📂 Project Structure

```
guardian_shield_app/
├── android/
│   └── app/src/main/AndroidManifest.xml   # All camera, SMS, GPS, foreground service permissions
├── lib/
│   ├── main.dart                          # App entrypoint & theme setup
│   ├── core/
│   │   ├── constants/                     # Colors, strings, trigger configs
│   │   ├── theme/                         # AMOLED Dark Theme
│   │   ├── security/                      # AES-256 encryption & PIN vault
│   │   └── permissions/                   # Runtime permission manager
│   ├── data/
│   │   ├── models/                        # Contacts, Sessions, Locations, Settings
│   │   └── repositories/                  # Storage & Firestore incident logs
│   ├── services/
│   │   ├── emergency_orchestrator.dart     # Central state coordinator
│   │   ├── shake_detection_service.dart   # 3x accelerometer shake listener
│   │   ├── location_tracker_service.dart  # Continuous GPS stream
│   │   ├── hidden_camera_service.dart     # Silent rolling video capture
│   │   └── sms_alert_service.dart         # SMS broadcast & auto-caller
│   └── presentation/
│       ├── widgets/                       # Pulse panic button, guardian cards
│       └── screens/
│           ├── onboarding/                # Privacy consent & initial PIN setup
│           ├── home/                      # Panic button dashboard & active banner
│           ├── contacts/                  # Add / manage up to 5 guardians
│           ├── disguise/                  # Fake Calculator & Low Battery decoys
│           ├── tracking/                  # Live GPS breadcrumbs & Google Maps link
│           ├── vault/                     # Encrypted incident logs & evidence
│           └── settings/                  # Hardware triggers & auto-call config
```

---

## 🚀 How to Run & Test

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Connect an Android device or emulator:**
   ```bash
   flutter devices
   ```

3. **Launch the application:**
   ```bash
   flutter run
   ```

4. **Default Initial Keys:**
   * **Master Safe PIN:** `1234` (used to stand down emergency and open vault)
   * **Decoy Calculator Trigger:** `9119=` (type this in the calculator to unlock)
