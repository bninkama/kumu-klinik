# Kumu Klinic — Architecture

```mermaid
flowchart LR
    subgraph Farmer["Farmer's phone (Android)"]
        A[Flutter app\nMaterial 3, Tok Pisin UI]
        H[(Hive\noffline cache\n+ photo queue)]
        A <--> H
    end

    subgraph GCP["Google Cloud"]
        FH[Firebase Hosting\nFlutter web build]
        CR[Cloud Run\nkumu-klinic-api\nNode.js Express]
        GEM[Gemini 2.0 Flash\nVision API]
        FS[(Firestore\ndiseases\nmarket_prices\ndiagnoses_history\nweather_cache)]
        TTS[Cloud Text-to-Speech]
        VAI[Vertex AI\nGemma 2B\noffline TP fallback]
    end

    OW[OpenWeatherMap API]

    A -- "POST /api/diagnose\nimage_base64" --> CR
    CR -- image --> GEM
    GEM -- bilingual JSON --> CR
    CR --> FS
    A -- "GET /api/weather, /api/prices" --> CR
    CR --> OW
    CR --> FS
    A -- spoken advice --> TTS
    H -. "no internet:\nGemma 2B on-device" .-> VAI
    FH --> A
```

## Data flow — diagnosis

1. Farmer photographs a diseased pod/leaf.
2. App base64-encodes and POSTs to Cloud Run.
3. Cloud Run calls **Gemini 2.0 Flash** (vision) with the PNG-expert prompt.
4. Gemini returns structured JSON: disease, confidence, EN + Tok Pisin advice.
5. Result saved to `diagnoses_history` in Firestore, returned to the app
   (target < 5 s online).
6. App renders the result card; **TTS** reads the Tok Pisin advice aloud.

## Offline path

- Disease library ships inside the app (`assets/diseases.json`) and is
  refreshed into Hive whenever the API is reachable.
- If `/api/diagnose` fails, the photo is queued in Hive and uploaded on
  reconnect. Library + history remain fully usable offline.
- For on-device translation fallback, **Gemma 2B via Vertex AI / AI Edge**
  is the planned offline model for Tok Pisin when the phone has no signal.

## Collections

| Collection | Writes | Purpose |
|---|---|---|
| `diseases` | seed script | 15+ PNG crop diseases, EN + TP fields |
| `market_prices` | seed/admin | price list shown in Weather & Market tab |
| `diagnoses_history` | API | every diagnosis, for analytics & retraining |
| `weather_cache` | API | cached forecasts per province |
