# Flutter + backend integration

This branch connects the Flutter dashboard to the Node.js/Express/MongoDB API.

## What changed
- Added `lib/services/backend_api.dart` to call the backend endpoints.
- Added the `http` Flutter dependency.
- Added Android internet permission and cleartext HTTP for local development.
- Updated the dashboard to create a monitoring session, sync monitoring state, send blink-rate/EAR/fatigue readings (throttled to at most once every five seconds unless a test control changes), log warning/high/critical transitions, and end the session when the screen is disposed.
- Added the backend service, MongoDB models, routes, environment example, seed script, and API tests under `backend/`.

## Run locally
Requirements: Flutter SDK, Node.js 18+, and MongoDB Community Server (or a MongoDB connection URI).

1. Start MongoDB.
2. In a terminal:
   ```powershell
   cd backend
   Copy-Item .env.example .env
   # If .env already exists, keep it and do not overwrite it.
   npm install
   npm run dev
   ```
3. Confirm `http://localhost:3000/api/health` responds with a successful health message.
4. In a second terminal at the Flutter project root:
   ```powershell
   flutter pub get
   flutter run
   ```

## API host configuration
- Android emulator: defaults to `http://10.0.2.2:3000/api`.
- iOS simulator / desktop: defaults to `http://127.0.0.1:3000/api`.
- Physical device: set `FATIGUE_API_URL` to your computer's LAN IP, for example `flutter run --dart-define=FATIGUE_API_URL=http://192.168.1.10:3000/api`. The phone and computer must be on the same network and the computer firewall must allow port 3000.

The Android cleartext HTTP setting is for local development only. Use HTTPS for a deployed backend.

## Important limitations
The existing dashboard still contains temporary test values for heart rate, blink rate, EAR, pilot detection, and fatigue level. This integration stores the current blink-rate, EAR, fatigue level, monitoring state, and fatigue events; it does not make those placeholder values into real sensor readings or add a new AI detector. Heart rate is intentionally not sent because the current app value is a hard-coded placeholder. Connect the real camera/ML and smartwatch data streams before relying on these readings for any safety decision.

The backend stores the fatigue level selected/determined by the Flutter app; it does not independently diagnose fatigue.
