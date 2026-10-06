require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { diagnose } = require('./gemini');
const { getForecast } = require('./weather');
const store = require('./store');

const app = express();
app.use(cors());
app.use(express.json({ limit: '12mb' }));

app.get('/health', (_req, res) => res.json({ ok: true, service: 'kumu-klinic-api' }));

// POST /api/diagnose  { image_base64, mime_type?, location_province?, crop_type? }
app.post('/api/diagnose', async (req, res) => {
  try {
    const { image_base64, mime_type, location_province, crop_type } = req.body || {};
    if (!image_base64) return res.status(400).json({ error: 'image_base64 is required' });

    const result = await diagnose(image_base64, mime_type || 'image/jpeg');
    if (result.disease_name === 'not_crop') {
      return res.json({ disease_name: 'not_crop', message_tpi: 'Dispela piksa i no kumu o gaden. Traim gen wantaim piksa bilong lif o kaikai.' });
    }

    const saved = await store.saveDiagnosis({
      ...result,
      location_province: location_province || null,
      crop_type: crop_type || result.crop || null,
    });
    res.json(saved);
  } catch (err) {
    console.error('[diagnose]', err);
    res.status(502).json({ error: 'diagnosis_failed', detail: err.message });
  }
});

// GET /api/weather?province=Morobe
app.get('/api/weather', async (req, res) => {
  try {
    res.json(await getForecast(req.query.province));
  } catch (err) {
    console.error('[weather]', err);
    res.status(502).json({ error: 'weather_failed', detail: err.message });
  }
});

// GET /api/prices
app.get('/api/prices', async (_req, res) => {
  try {
    res.json({ prices: await store.listPrices() });
  } catch (err) {
    console.error('[prices]', err);
    res.status(502).json({ error: 'prices_failed', detail: err.message });
  }
});

// GET /api/diseases — offline-capable disease library
app.get('/api/diseases', async (_req, res) => {
  try {
    res.json({ diseases: await store.listDiseases() });
  } catch (err) {
    res.status(502).json({ error: 'diseases_failed', detail: err.message });
  }
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Kumu Klinic API listening on :${port}`));
