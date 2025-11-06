<div align="center">

<h1>Rizzume</h1>

Social recruiting meets Gen‑Z chat. Build your profile, browse jobs, and talk peer‑to‑peer with zero server message storage.

<p>
	<a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white"></a>
	<a href="https://dart.dev"><img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white"></a>
	<a href="https://firebase.google.com/"><img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black"></a>
	<a href="https://webrtc.org/"><img alt="WebRTC" src="https://img.shields.io/badge/WebRTC-DataChannels-333333?logo=webrtc&logoColor=white"></a>
	<a href="https://socket.io/"><img alt="Socket.IO" src="https://img.shields.io/badge/Socket.IO-Signaling-010101?logo=socketdotio&logoColor=white"></a>
	<a href="https://docs.hivedb.dev/"><img alt="Hive" src="https://img.shields.io/badge/Hive-Local%20Cache-FF7A00?logo=hive&logoColor=white"></a>
</p>

</div>

## Overview

Rizzume is a Flutter app that blends social profiles and job discovery with a real‑time, privacy‑minded chat. Messaging is powered by WebRTC DataChannels and a lightweight Python (Flask + Socket.IO) signaling server—no messages are persisted on any backend, only on the device via Hive.

## ✨ Features

- Tap usernames or avatars anywhere to jump to their profile
- Global Search tab in the bottom navbar for fast discovery
- Jobs tab with an Applications button (top‑right) opening matches in a sheet
- Clean profile layout with Follow and Message actions
- P2P chat over WebRTC DataChannels (end‑to‑end transport security via DTLS‑SRTP)
	- Flask + Socket.IO signaling server (no chat DB)
	- Google STUN servers by default; TURN can be added for tougher NATs
	- Local‑first cache using Hive, offline message history per device
- Smart connectivity UX
	- “Get a better Network already broski” shows only during loading/connecting when offline
	- No persistent blocking banners
- Multi‑platform targets: Android, iOS, Web, macOS, Windows, Linux

## 🧩 Tech Stack

- Flutter, Dart
- Firebase (Auth, Firestore, Storage)
- flutter_webrtc, socket_io_client
- Hive + hive_flutter for local storage
- Python: Flask, Flask‑SocketIO, CORS (for signaling)

## 🏛️ Architecture

- Frontend: Flutter
	- UI: screens under `lib/screens/**`
	- State/Services: `lib/services/**`
	- Models: `lib/models/**`
	- Routes: `lib/routes/app_routes.dart`
- Chat: `WebRTCChatService` in `lib/services/webrtc_chat_service.dart`
	- Creates RTCPeerConnection + RTCDataChannel
	- Signals via Socket.IO to the server
	- Persists messages locally with Hive
- Backend signaling: `rizzume_backend/signaling_server.py`
	- Endpoints/events: register, offer, answer, ice‑candidate, health
	- Port configurable via `PORT` env var

## 🚀 Quickstart

### Prerequisites

- Flutter 3.x and Dart SDK
- Xcode (iOS), Android Studio/SDK (Android) as needed
- Python 3.10+ for the signaling server
- A Firebase project (Auth/Firestore/Storage) and configs

### 1) Install dependencies

```bash
flutter pub get
```

If you plan to regenerate Hive adapters (already generated in repo):

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 2) Firebase configuration (required for build)

Add your Firebase app config files locally (they are intentionally .gitignored):

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

The file `lib/firebase_options.dart` is included. If you re‑create Firebase projects, re‑generate this file or use `flutterfire configure`.

### 3) Configure the signaling server URL

Update the constant in `lib/services/webrtc_chat_service.dart`:

```dart
static const String SIGNALING_SERVER = 'http://<your-host-or-ip>:<port>'; // e.g. http://192.168.1.20:5051
```

### 4) Run the signaling server (Python)

```bash
cd rizzume_backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r signaling_requirements.txt
export PORT=5051           # Use a non-conflicting port (5000 is often taken by macOS AirPlay)
python signaling_server.py
```

Server starts on `http://0.0.0.0:PORT`. Use your machine IP (not 0.0.0.0) in the Flutter app.

### 5) Run the Flutter app

```bash
# Android (device or emulator)
flutter run -d android

# iOS (simulator)
flutter run -d ios

# Web
flutter run -d chrome
```

## 📁 Project Structure (high level)

```
lib/
	core/              # theme, colors, config, utils
	models/            # data models (Hive‑annotated chat message, etc.)
	routes/            # app routes
	screens/           # UI screens (auth, chat, home, profile, settings)
	services/          # Firebase, jobs, WebRTC chat, network
	widgets/           # shared UI components (NetworkGuard, etc.)
rizzume_backend/     # Flask + Socket.IO signaling server
assets/              # images, icons, animations, html
```

## 🧪 Development

Run tests:

```bash
flutter test
```

Analysis (lints configured via `analysis_options.yaml`):

```bash
dart analyze
```

Generate Hive adapters (already generated):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 🛠 Troubleshooting

- Port 5000 already in use on macOS
	- macOS AirPlay Receiver often binds 5000; use `PORT=5051` (or any free port) for the signaling server and update `SIGNALING_SERVER` in the Flutter app.
- Android build requires compile/target SDK 36
	- Project is configured for `compileSdk=36`, `targetSdk=36`, `minSdk=21` to satisfy plugin requirements (e.g., `flutter_webrtc`). Ensure your Android SDKs match.
- Hive adapter missing errors
	- Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `*.g.dart` if needed.
- WebRTC connectivity behind strict NATs
	- Consider adding a TURN server to the ICE servers list in `WebRTCChatService.configuration` for reliability.

## 🔒 Security & Privacy

- Chat messages are exchanged directly over WebRTC DataChannels and are not stored on any backend.
- Messages are cached locally on the device using Hive.
- Firebase credentials/configs are not committed to the repo—add them locally.

## 🤝 Contributing

PRs and issues are welcome. Please open a discussion for larger changes (architecture, data model, or UX shifts) before starting.

## 📄 License

Copyright (c) 2025 Pratham Sangurdekar.

This project does not currently include an open‑source license. If you intend to use or distribute this code, please add an appropriate `LICENSE` file or contact the author.

