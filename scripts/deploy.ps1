# Deploy Kumu Klinic to Google Cloud — ADC edition (no API keys; org policy).
# Prereqs: gcloud + firebase CLI, `gcloud auth login` AND
#          `gcloud auth application-default login` completed, billing enabled.
# Usage:  .\deploy.ps1 -ProjectId project-d0306dc0-8de8-4965-893 [-OpenWeatherKey KEY]
param(
  [Parameter(Mandatory=$true)][string]$ProjectId,
  [string]$Region = "australia-southeast1",
  [string]$OpenWeatherKey = "",
  [string]$Location = "global"
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$sa = "kumu-klinic-api@$ProjectId.iam.gserviceaccount.com"

Write-Host "==> Setting project $ProjectId"
gcloud config set project $ProjectId
gcloud services enable run.googleapis.com firestore.googleapis.com cloudbuild.googleapis.com aiplatform.googleapis.com firebase.googleapis.com

Write-Host "==> Creating service account + Vertex AI access"
gcloud iam service-accounts create kumu-klinic-api --display-name "Kumu Klinic API" 2>$null
gcloud projects add-iam-policy-binding $ProjectId --member "serviceAccount:$sa" --role "roles/aiplatform.user"
gcloud projects add-iam-policy-binding $ProjectId --member "serviceAccount:$sa" --role "roles/datastore.user"

Write-Host "==> Deploying backend to Cloud Run"
gcloud run deploy kumu-klinic-api `
  --source "$root\backend" `
  --region $Region `
  --service-account $sa `
  --allow-unauthenticated `
  --set-env-vars "GCP_PROJECT=$ProjectId,GCP_LOCATION=$Location,OPENWEATHER_API_KEY=$OpenWeatherKey"

$apiUrl = gcloud run services describe kumu-klinic-api --region $Region --format "value(status.url)"
Write-Host "==> API URL: $apiUrl"

Write-Host "==> Ensuring Firestore database exists"
gcloud firestore databases create --region=$Region 2>$null

Write-Host "==> Seeding Firestore"
$env:GCP_PROJECT = $ProjectId
node "$root\backend\src\seed.js"

Write-Host "==> Building Flutter web"
Push-Location "$root\app"
flutter pub get
flutter build web --dart-define=API_BASE=$apiUrl
Pop-Location

Write-Host "==> Deploying web to Firebase Hosting"
firebase deploy --only hosting,firestore:rules --project $ProjectId

Write-Host "Done. App: https://$ProjectId.web.app  API: $apiUrl"
