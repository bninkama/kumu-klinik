// Weather: OpenWeatherMap 3-day forecast for PNG provincial centres.
// Falls back to realistic demo data when no API key is configured.
const PROVINCE_COORDS = {
  'port moresby': { lat: -9.478, lon: 147.15, name: 'Port Moresby' },
  'central': { lat: -9.05, lon: 147.6, name: 'Central' },
  'morobe': { lat: -6.8, lon: 147.0, name: 'Morobe (Lae)' },
  'eastern highlands': { lat: -6.32, lon: 145.38, name: 'Eastern Highlands (Goroka)' },
  'western highlands': { lat: -5.86, lon: 144.23, name: 'Western Highlands (Mt Hagen)' },
  'simbu': { lat: -6.05, lon: 144.97, name: 'Simbu (Kundiawa)' },
  'east new britain': { lat: -4.35, lon: 152.27, name: 'East New Britain (Kokopo)' },
  'madang': { lat: -5.22, lon: 145.79, name: 'Madang' },
  'east sepik': { lat: -3.55, lon: 143.63, name: 'East Sepik (Wewak)' },
  'sandaun': { lat: -3.55, lon: 141.7, name: 'Sandaun (Vanimo)' },
  'new ireland': { lat: -2.58, lon: 150.8, name: 'New Ireland (Kavieng)' },
  'west new britain': { lat: -5.55, lon: 150.14, name: 'West New Britain (Kimbe)' },
  'bougainville': { lat: -6.22, lon: 155.57, name: 'Bougainville (Buka)' },
  'milne bay': { lat: -10.31, lon: 150.42, name: 'Milne Bay (Alotau)' },
  'oro': { lat: -8.9, lon: 148.22, name: 'Oro (Popondetta)' },
  'southern highlands': { lat: -6.27, lon: 143.95, name: 'Southern Highlands (Mendi)' },
  'eng a': { lat: -5.48, lon: 143.66, name: 'Enga (Wabag)' },
  'enga': { lat: -5.48, lon: 143.66, name: 'Enga (Wabag)' },
  'hela': { lat: -6.28, lon: 142.83, name: 'Hela (Tari)' },
  'jiwaka': { lat: -5.87, lon: 144.6, name: 'Jiwaka (Banz)' },
  'gulf': { lat: -7.97, lon: 145.77, name: 'Gulf (Kerema)' },
  'western': { lat: -8.75, lon: 143.03, name: 'Western (Daru)' },
  'manus': { lat: -2.05, lon: 147.27, name: 'Manus (Lorengau)' },
};

function resolveProvince(province) {
  const key = String(province || 'Port Moresby').toLowerCase().trim();
  return PROVINCE_COORDS[key] || PROVINCE_COORDS['port moresby'];
}

function demoForecast(place) {
  const today = new Date();
  const day = (i) => {
    const d = new Date(today);
    d.setDate(d.getDate() + i);
    return d.toISOString().slice(0, 10);
  };
  return {
    province: place.name,
    source: 'demo',
    forecast: [
      { date: day(0), condition: 'Partly cloudy', temp_c: 31, rain_chance_pct: 30, advisory_en: 'Good day for garden work.', advisory_tpi: 'Gutpela de bilong wok long gaden.' },
      { date: day(1), condition: 'Afternoon showers', temp_c: 30, rain_chance_pct: 60, advisory_en: 'Rain likely after lunch — finish spraying early.', advisory_tpi: 'Ren i laik kamap bihain long belo — pinisim spret kwik.' },
      { date: day(2), condition: 'Heavy rain', temp_c: 28, rain_chance_pct: 90, advisory_en: 'Strong rain coming. Clear drains, harvest ripe pods now.', advisory_tpi: 'Bikpela ren i kam. Klinim dren, katim mau kumu nau.' },
    ],
    alert: { level: 'medium', message_en: `Strong rain expected in ${place.name} in 2 days`, message_tpi: `Bikpela ren i kam long ${place.name} inap 2 de` },
  };
}

async function getForecast(province) {
  const place = resolveProvince(province);
  const key = process.env.OPENWEATHER_API_KEY;
  if (!key) return demoForecast(place);

  const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${place.lat}&lon=${place.lon}&appid=${key}&units=metric&cnt=24`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`OpenWeatherMap ${res.status}`);
  const json = await res.json();

  // Collapse 3-hourly data into per-day summaries.
  const days = new Map();
  for (const item of json.list) {
    const date = item.dt_txt.slice(0, 10);
    const d = days.get(date) || { temps: [], rain: 0, descs: [] };
    d.temps.push(item.main.temp);
    d.rain = Math.max(d.rain, (item.pop || 0) * 100);
    d.descs.push(item.weather?.[0]?.description || '');
    days.set(date, d);
  }
  const forecast = [...days.entries()].slice(0, 3).map(([date, d]) => ({
    date,
    condition: d.descs[Math.floor(d.descs.length / 2)] || 'unknown',
    temp_c: Math.round(d.temps.reduce((a, b) => a + b, 0) / d.temps.length),
    rain_chance_pct: Math.round(d.rain),
    advisory_en: d.rain >= 70 ? 'Heavy rain expected — clear drains and secure crops.' : 'Conditions look workable.',
    advisory_tpi: d.rain >= 70 ? 'Bikpela ren i kam — klinim dren na lukautim kaikai.' : 'Taim i luk orait bilong wok gaden.',
  }));

  const worst = forecast.reduce((a, b) => (b.rain_chance_pct > a.rain_chance_pct ? b : a), forecast[0]);
  return {
    province: place.name,
    source: 'openweathermap',
    forecast,
    alert: worst && worst.rain_chance_pct >= 70
      ? { level: 'medium', message_en: `Strong rain expected in ${place.name} on ${worst.date}`, message_tpi: `Bikpela ren i kam long ${place.name} long ${worst.date}` }
      : null,
  };
}

module.exports = { getForecast };
