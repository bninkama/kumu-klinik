// Gemini 2.0 Flash Vision diagnosis via Vertex AI + Application Default
// Credentials (org policy disallows API keys). On Cloud Run, ADC is the
// attached service account automatically; locally, run
// `gcloud auth application-default login` first.
// Falls back to a canned demo response when DEMO_MODE=true or no GCP
// project is configured, so the app is still demonstrable offline.
const fs = require('fs');
const path = require('path');

const PROMPT = `You are a Papua New Guinea agriculture expert. Analyze the crop image.
Identify disease from this list: [Black Pod, Cocoa Pod Borer, Frosty Pod, Coffee Leaf Rust, Coffee Berry Disease, Coffee Berry Borer, Sweet Potato Weevil, Taro Leaf Blight, Taro Beetle, Banana Bunchy Top, Black Sigatoka, Fall Armyworm, Cassava Mosaic, Peanut Rust, Vascular Streak Dieback, Healthy].
Return JSON only with this exact shape:
{
  "disease_name": "string from the list",
  "confidence_score": 0.0-1.0,
  "scientific_name": "string",
  "crop": "string",
  "urgency": "low|medium|high",
  "english": { "cause": "...", "immediate_action": "...", "organic_treatment": "...", "chemical_treatment": "...", "prevention": "..." },
  "tok_pisin": { "cause": "...", "immediate_action": "...", "organic_treatment": "...", "chemical_treatment": "...", "prevention": "..." }
}
Write tok_pisin in simple Tok Pisin a village farmer understands. Prefer locally available materials (lime, wood ash, pruning, burning infected parts, soap water) before chemicals.
If the image is not a crop/plant, return: {"disease_name": "not_crop", "confidence_score": 1.0}`;

const diseases = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'data', 'diseases.json'), 'utf8')
);

function demoDiagnosis() {
  const d = diseases.find((x) => x.id === 'black-pod');
  return {
    disease_name: 'Black Pod',
    confidence_score: 0.92,
    scientific_name: d.scientific_name,
    crop: 'cocoa',
    urgency: d.urgency,
    demo_mode: true,
    english: {
      cause: d.cause_en,
      immediate_action: d.treatment_en,
      organic_treatment: d.organic_treatment_en,
      chemical_treatment: d.chemical_treatment_en,
      prevention: d.prevention_en,
    },
    tok_pisin: {
      cause: d.cause_tpi,
      immediate_action: d.treatment_tpi,
      organic_treatment: d.organic_treatment_tpi,
      chemical_treatment: d.chemical_treatment_tpi,
      prevention: d.prevention_tpi,
    },
  };
}

let _ai;
function client() {
  if (_ai) return _ai;
  const project = process.env.GCP_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  if (!project) return null;
  const { GoogleGenAI } = require('@google/genai');
  // vertexai: true -> uses ADC (service account on Cloud Run, or
  // `gcloud auth application-default login` locally). No API keys.
  _ai = new GoogleGenAI({
    vertexai: true,
    project,
    location: process.env.GCP_LOCATION || 'global',
  });
  return _ai;
}

async function diagnose(imageBase64, mimeType = 'image/jpeg') {
  const ai = process.env.DEMO_MODE === 'true' ? null : client();
  if (!ai) return demoDiagnosis();

  const result = await ai.models.generateContent({
    model: process.env.GEMINI_MODEL || 'gemini-2.5-flash',
    contents: [
      {
        role: 'user',
        parts: [
          { text: PROMPT },
          { inlineData: { mimeType, data: imageBase64 } },
        ],
      },
    ],
    config: { responseMimeType: 'application/json' },
  });

  const text = result.text || '{}';
  try {
    return JSON.parse(text);
  } catch {
    // Gemini sometimes wraps JSON in a code fence despite responseMimeType.
    const cleaned = text.replace(/```json|```/g, '').trim();
    return JSON.parse(cleaned);
  }
}

module.exports = { diagnose, demoDiagnosis };
