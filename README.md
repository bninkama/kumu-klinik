# KUMU KLINIC

AI agriculture & climate advisor for Papua New Guinea smallholder farmers.
Photo of a sick crop -> Gemini 2.0 Flash Vision diagnosis -> treatment advice
in **Tok Pisin + English**, spoken aloud, working offline.

**Google Cloud AI Builder Cup 2026 — Sustainability & Social Impact**

## Repo layout

```
kumu-klinic/
  backend/            Node.js Express API (deploys to Cloud Run)
    data/diseases.json  16-entry PNG disease library (also bundled in the app)
    src/index.js        /api/diagnose, /api/weather, /api/prices, /api/diseases
    src/gemini.js       Gemini Vision call + demo-mode fallback
    src/store.js        Firestore, with in-memory fallback for local dev
    src/weather.js      OpenWeatherMap 3-day forecast + PNG province coords
    src/seed.js         Firestore seeder
    Dockerfile
  app/                Flutter app (Android first, web via Firebase Hosting)
    lib/screens/        home, diagnosis, library, weather & market
    lib/services/       api, Hive offline store, TTS
    assets/diseases.json  bundled offline library
  firestore.rules
  firebase.json       Hosting -> app/build/web
  scripts/deploy.sh   deploy.ps1/deploy.sh — one-command GCP deploy
  docs/               architecture diagram, demo video script
```

## Quick start (local, no GCP needed)

```powershell
cd backend
npm install
npm start          # http://localhost:8080 — demo mode, no keys required
```

Without GCP credentials the API returns a canned Black Pod diagnosis so the
full app flow is testable. For live diagnosis the backend uses **Vertex AI
with Application Default Credentials** (org policy: no API keys) —
`gcloud auth application-default login` locally, service account on Cloud Run.
See `backend/.env.example`.

## Run the app

```powershell
cd app
flutter create --platforms android,ios,web .   # first time only: generates platform shells
flutter pub get
flutter run --dart-define=API_BASE=http://localhost:8080
# or on an Android emulator, API_BASE default (10.0.2.2:8080) already points at localhost
```

## Deploy to Google Cloud

```powershell
.\scripts\deploy.ps1 -ProjectId YOUR_PROJECT [-OpenWeatherKey KEY]
# or on Linux/macOS:
./scripts/deploy.sh YOUR_PROJECT [OPENWEATHER_KEY]
```

Requires `gcloud auth login` + `gcloud auth application-default login` (no API
keys — org policy). Model: `gemini-2.5-flash` via Vertex AI (2.0 is no longer
available on Vertex for new projects).

This deploys the API to Cloud Run, seeds Firestore, builds Flutter web and
pushes it to Firebase Hosting. Requires `gcloud` + `firebase` CLI and billing.

## API

| Method | Path | Body / Params | Returns |
|---|---|---|---|
| POST | `/api/diagnose` | `{image_base64, mime_type?, location_province?, crop_type?}` | Diagnosis JSON (EN + Tok Pisin advice) |
| GET | `/api/weather` | `?province=Morobe` | 3-day forecast + alert |
| GET | `/api/prices` | — | Market price list |
| GET | `/api/diseases` | — | Disease library |

## Design notes

- **Tok Pisin first** — UI defaults to Tok Pisin; advice comes back bilingual.
- **Offline-first** — disease library is bundled as an asset + Hive cache;
  failed diagnoses queue in Hive for upload on reconnect.
- **Low-literacy UX** — 140px hero button, icons everywhere, TTS playback,
  17–24pt text, high-contrast green/brown/white.
- `POST /api/diagnose` returns `disease_name: "not_crop"` for non-plant photos.
