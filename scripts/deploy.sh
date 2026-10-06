#!/usr/bin/env bash
# Deploy Kumu Klinic to Google Cloud — ADC edition (no API keys).
# Prereqs: `gcloud auth login` + `gcloud auth application-default login` done.
# Usage: ./deploy.sh <project-id> [openweather-key]
set -euo pipefail

PROJECT_ID="${1:?usage: deploy.sh <project-id> [openweather-key]}"
OWM_KEY="${2:-}"
REGION="${REGION:-australia-southeast1}"
LOCATION="${LOCATION:-global}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SA="kumu-klinic-api@$PROJECT_ID.iam.gserviceaccount.com"

gcloud config set project "$PROJECT_ID"
gcloud services enable run.googleapis.com firestore.googleapis.com cloudbuild.googleapis.com aiplatform.googleapis.com firebase.googleapis.com

echo "==> Service account + Vertex AI access"
gcloud iam service-accounts create kumu-klinic-api --display-name "Kumu Klinic API" || true
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member "serviceAccount:$SA" --role "roles/aiplatform.user"
gcloud projects add-iam-policy-binding "$PROJECT_ID" --member "serviceAccount:$SA" --role "roles/datastore.user"

echo "==> Deploying backend to Cloud Run"
gcloud run deploy kumu-klinic-api \
  --source "$ROOT/backend" \
  --region "$REGION" \
  --service-account "$SA" \
  --allow-unauthenticated \
  --set-env-vars "GCP_PROJECT=$PROJECT_ID,GCP_LOCATION=$LOCATION,OPENWEATHER_API_KEY=$OWM_KEY"

API_URL=$(gcloud run services describe kumu-klinic-api --region "$REGION" --format 'value(status.url)')
echo "==> API URL: $API_URL"

echo "==> Ensuring Firestore database exists"
gcloud firestore databases create --region="$REGION" || true

echo "==> Seeding Firestore"
GCP_PROJECT="$PROJECT_ID" node "$ROOT/backend/src/seed.js"

echo "==> Building Flutter web"
(cd "$ROOT/app" && flutter pub get && flutter build web --dart-define="API_BASE=$API_URL")

echo "==> Deploying web to Firebase Hosting"
firebase deploy --only hosting,firestore:rules --project "$PROJECT_ID"

echo "Done. App: https://$PROJECT_ID.web.app  API: $API_URL"
