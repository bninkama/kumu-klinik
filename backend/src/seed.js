// Seeds the `diseases` and `market_prices` collections in Firestore.
// Usage: GCP_PROJECT=your-project node src/seed.js
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { db } = require('./store');

const diseases = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'data', 'diseases.json'), 'utf8')
);

const PRICES = [
  { crop: 'Cocoa (wet bean)', unit: 'kg', price_kina: 5.0, market: 'Lae' },
  { crop: 'Cocoa (dry bean)', unit: 'kg', price_kina: 12.0, market: 'Lae' },
  { crop: 'Coffee (parchment)', unit: 'kg', price_kina: 15.0, market: 'Goroka' },
  { crop: 'Coffee (cherry)', unit: 'kg', price_kina: 3.5, market: 'Goroka' },
  { crop: 'Kaukau (sweet potato)', unit: 'bag', price_kina: 40.0, market: 'Port Moresby' },
  { crop: 'Taro', unit: 'bag', price_kina: 60.0, market: 'Port Moresby' },
  { crop: 'Banana', unit: 'bunch', price_kina: 15.0, market: 'Mt Hagen' },
  { crop: 'Copra', unit: 'kg', price_kina: 2.5, market: 'Madang' },
];

async function main() {
  if (!db) {
    console.error('Firestore not configured. Set GCP_PROJECT and credentials first.');
    process.exit(1);
  }
  const batch = db.batch();
  for (const d of diseases) batch.set(db.collection('diseases').doc(d.id), d);
  for (const [i, p] of PRICES.entries()) batch.set(db.collection('market_prices').doc(`price-${i}`), p);
  await batch.commit();
  console.log(`Seeded ${diseases.length} diseases and ${PRICES.length} prices.`);
}

main().catch((e) => { console.error(e); process.exit(1); });
