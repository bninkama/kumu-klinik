// Storage layer: uses Firestore when credentials are configured,
// otherwise falls back to an in-memory store seeded from data/diseases.json
// so the API works locally with zero GCP setup.
const fs = require('fs');
const path = require('path');

const diseasesSeed = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'data', 'diseases.json'), 'utf8')
);

const DEFAULT_PRICES = [
  { crop: 'Cocoa (wet bean)', unit: 'kg', price_kina: 5.0, market: 'Lae' },
  { crop: 'Cocoa (dry bean)', unit: 'kg', price_kina: 12.0, market: 'Lae' },
  { crop: 'Coffee (parchment)', unit: 'kg', price_kina: 15.0, market: 'Goroka' },
  { crop: 'Coffee (cherry)', unit: 'kg', price_kina: 3.5, market: 'Goroka' },
  { crop: 'Kaukau (sweet potato)', unit: 'bag', price_kina: 40.0, market: 'Port Moresby' },
  { crop: 'Taro', unit: 'bag', price_kina: 60.0, market: 'Port Moresby' },
  { crop: 'Banana', unit: 'bunch', price_kina: 15.0, market: 'Mt Hagen' },
  { crop: 'Copra', unit: 'kg', price_kina: 2.5, market: 'Madang' },
];

function initFirestore() {
  try {
    const admin = require('firebase-admin');
    const projectId = process.env.GCP_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
    if (!projectId && !process.env.GOOGLE_APPLICATION_CREDENTIALS) return null;
    if (admin.apps.length === 0) {
      admin.initializeApp(projectId ? { projectId } : undefined);
    }
    const db = admin.firestore();
    console.log('[store] Firestore connected');
    return db;
  } catch (err) {
    console.warn('[store] Firestore unavailable, using in-memory store:', err.message);
    return null;
  }
}

const db = initFirestore();

const memory = {
  diseases: new Map(diseasesSeed.map((d) => [d.id, d])),
  diagnoses: [],
  prices: DEFAULT_PRICES,
};

async function listDiseases() {
  if (!db) return [...memory.diseases.values()];
  const snap = await db.collection('diseases').get();
  if (snap.empty) return [...memory.diseases.values()];
  return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function getDisease(id) {
  if (!db) return memory.diseases.get(id) || null;
  const doc = await db.collection('diseases').doc(id).get();
  return doc.exists ? { id: doc.id, ...doc.data() } : null;
}

async function saveDiagnosis(record) {
  const entry = { ...record, created_at: new Date().toISOString() };
  if (!db) {
    memory.diagnoses.push(entry);
    return entry;
  }
  const ref = await db.collection('diagnoses_history').add(entry);
  return { id: ref.id, ...entry };
}

async function listPrices() {
  if (!db) return memory.prices;
  const snap = await db.collection('market_prices').orderBy('crop').get();
  if (snap.empty) return memory.prices;
  return snap.docs.map((doc) => doc.data());
}

module.exports = { listDiseases, getDisease, saveDiagnosis, listPrices, db };
