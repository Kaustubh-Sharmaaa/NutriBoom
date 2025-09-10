import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const DATA_DIR = path.join(__dirname, 'data');
const DB_PATH = path.join(DATA_DIR, 'db.json');

function ensureDb() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(DB_PATH)) {
    const initial = {
      targetCalories: 1200,
      targetProtein: 100,
      consumed: [],
      foods: [
        { name: 'Apple (1 medium)', calorie: 95, protein: 0.5 },
        { name: 'Banana (1 medium)', calorie: 105, protein: 1.3 },
        { name: 'Chicken Breast (100g)', calorie: 165, protein: 31 },
        { name: 'Egg (1 large)', calorie: 78, protein: 6 },
        { name: 'Rice, cooked (1 cup)', calorie: 206, protein: 4.3 },
        { name: 'Oats, dry (40g)', calorie: 150, protein: 5 },
        { name: 'Milk, 2% (1 cup)', calorie: 122, protein: 8 },
        { name: 'Greek Yogurt (170g)', calorie: 100, protein: 17 }
      ]
    };
    fs.writeFileSync(DB_PATH, JSON.stringify(initial, null, 2));
  }
}

function readDb() {
  ensureDb();
  const raw = fs.readFileSync(DB_PATH, 'utf-8');
  return JSON.parse(raw);
}

function writeDb(db) {
  fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2));
}

function totals(db) {
  const consumedCalories = db.consumed.reduce((s, f) => s + Number(f.calorie || 0), 0);
  const consumedProtein = db.consumed.reduce((s, f) => s + Number(f.protein || 0), 0);
  return { consumedCalories, consumedProtein, targetCalories: db.targetCalories, targetProtein: db.targetProtein };
}

// Health check
app.get('/api/health', (_req, res) => res.json({ ok: true }));

// Config: targets
app.get('/api/config', (_req, res) => {
  const db = readDb();
  res.json({ targetCalories: db.targetCalories, targetProtein: db.targetProtein });
});

// Totals + entries
app.get('/api/consumed', (_req, res) => {
  const db = readDb();
  res.json({ ...totals(db), entries: db.consumed });
});

// Add a consumed entry
// Add a consumed entry with amount + unit. Payload supports two modes:
// - Simple: { name, calorie, protein } (legacy)
// - Detailed: { name, amount, servingSize, servingUnit, per, baseCalorie, baseProtein }
//   Calculated calories/protein = base * (amount/servingSize)
app.post('/api/consume', (req, res) => {
  const p = req.body || {};
  const db = readDb();

  function pushAndReturn(entry) {
    db.consumed.push(entry);
    writeDb(db);
    return res.json({ ok: true, ...totals(db) });
  }

  if (p && p.name && p.amount != null && p.servingSize != null && p.baseCalorie != null && p.baseProtein != null) {
    const amount = Number(p.amount);
    const servingSize = Number(p.servingSize) || 1;
    const factor = servingSize === 0 ? 0 : (amount / servingSize);
    const calorie = Number(p.baseCalorie) * factor;
    const protein = Number(p.baseProtein) * factor;
    const entry = {
      name: String(p.name),
      amount,
      servingSize,
      servingUnit: p.servingUnit || (p.per === '100 g' ? 'g' : 'serving'),
      per: p.per || (p.servingUnit ? 'serving' : undefined),
      baseCalorie: Number(p.baseCalorie),
      baseProtein: Number(p.baseProtein),
      calorie,
      protein,
    };
    return pushAndReturn(entry);
  }

  // Legacy simple payload
  const { name, calorie, protein } = p;
  if (!name || isNaN(Number(calorie)) || isNaN(Number(protein))) {
    return res.status(400).json({ error: 'Invalid payload' });
  }
  return pushAndReturn({ name, calorie: Number(calorie), protein: Number(protein) });
});

// Remove consumed entry by index
app.delete('/api/consume/:index', (req, res) => {
  const idx = Number(req.params.index);
  const db = readDb();
  if (Number.isNaN(idx) || idx < 0 || idx >= db.consumed.length) {
    return res.status(404).json({ error: 'Not found' });
  }
  db.consumed.splice(idx, 1);
  writeDb(db);
  res.json({ ok: true, ...totals(db) });
});

// Update consumed entry amount and recompute nutrients
app.put('/api/consume/:index', (req, res) => {
  const idx = Number(req.params.index);
  const { amount } = req.body || {};
  const db = readDb();
  if (Number.isNaN(idx) || idx < 0 || idx >= db.consumed.length) {
    return res.status(404).json({ error: 'Not found' });
  }
  if (amount == null || isNaN(Number(amount))) {
    return res.status(400).json({ error: 'Invalid amount' });
  }
  const entry = db.consumed[idx];
  // If we have base fields, recompute; else scale proportionally if we can
  const newAmount = Number(amount);
  if (entry.baseCalorie != null && entry.baseProtein != null && entry.servingSize) {
    const factor = entry.servingSize === 0 ? 0 : (newAmount / Number(entry.servingSize));
    entry.amount = newAmount;
    entry.calorie = Number(entry.baseCalorie) * factor;
    entry.protein = Number(entry.baseProtein) * factor;
  } else {
    // Fallback: keep name, override amount if present and leave calorie/protein unchanged
    entry.amount = newAmount;
  }
  db.consumed[idx] = entry;
  writeDb(db);
  res.json({ ok: true, ...totals(db) });
});

// Food search
// Uses USDA FoodData Central if FDC_API_KEY is set; otherwise falls back to local list.
app.get('/api/foods', async (req, res) => {
  const q = String(req.query.q || '').trim();
  const db = readDb();
  if (!q) {
    return res.json(db.foods.slice(0, 25));
  }
  const FDC_API_KEY = process.env.FDC_API_KEY;
  if (!FDC_API_KEY) {
    const list = db.foods.filter(f => f.name.toLowerCase().includes(q.toLowerCase()));
    return res.json(list.slice(0, 25));
  }

  try {
    const url = 'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=' + encodeURIComponent(FDC_API_KEY);
    const body = {
      query: q,
      pageSize: 25,
      sortBy: 'score',
      sortOrder: 'desc',
      dataType: ['Branded', 'Survey (FNDDS)', 'SR Legacy', 'Foundation'],
      requireAllWords: false
    };
    const r = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    if (!r.ok) throw new Error('FDC error ' + r.status);
    const data = await r.json();
    const foods = Array.isArray(data.foods) ? data.foods : [];

    function pickNutrientFromArray(arr, names) {
      if (!Array.isArray(arr)) return undefined;
      const n = arr.find(x => x && typeof x.nutrientName === 'string' && names.some(nn => x.nutrientName.toLowerCase().includes(nn)));
      if (!n || n.value == null) return undefined;
      return Number(n.value);
    }

    const results = foods.map(f => {
      const title = [f.description, f.brandName || f.brandOwner].filter(Boolean).join(' - ').trim();
      let cal, protein, carbs, fat, per;
      if (f.labelNutrients) {
        const ln = f.labelNutrients;
        cal = ln.calories?.value != null ? Number(ln.calories.value) : undefined;
        protein = ln.protein?.value != null ? Number(ln.protein.value) : undefined;
        carbs = ln.carbohydrates?.value != null ? Number(ln.carbohydrates.value) : undefined;
        fat = ln.fat?.value != null ? Number(ln.fat.value) : undefined;
        per = 'serving';
      }
      if (cal == null || protein == null) {
        // fallback to generic nutrients
        cal = cal ?? pickNutrientFromArray(f.foodNutrients, ['energy', 'calorie']);
        protein = protein ?? pickNutrientFromArray(f.foodNutrients, ['protein']);
        carbs = carbs ?? pickNutrientFromArray(f.foodNutrients, ['carbohydrate']);
        fat = fat ?? pickNutrientFromArray(f.foodNutrients, ['fat']);
      }
      if (!title) return null;
      if (cal == null && protein == null) return null;
      return {
        name: title,
        calorie: cal != null ? Number(cal) : 0,
        protein: protein != null ? Number(protein) : 0,
        carbs: carbs != null ? Number(carbs) : undefined,
        fat: fat != null ? Number(fat) : undefined,
        per: per,
        servingSize: f.servingSize != null ? Number(f.servingSize) : (per === 'serving' ? 1 : 100),
        servingUnit: f.servingSizeUnit || (per === 'serving' ? 'serving' : 'g')
      };
    }).filter(Boolean).slice(0, 25);

    // Ensure query presence in name to keep suggestions relevant
    const qlc = q.toLowerCase();
    const filtered = results.filter(it => (it.name || '').toLowerCase().includes(qlc));
    return res.json(filtered.length ? filtered : results);
  } catch (e) {
    const fallback = db.foods.filter(f => f.name.toLowerCase().includes(q.toLowerCase())).slice(0, 25);
    return res.json(fallback);
  }
});

// Update targets
app.post('/api/targets', (req, res) => {
  const { targetCalories, targetProtein } = req.body || {};
  const db = readDb();
  if (targetCalories !== undefined) db.targetCalories = Number(targetCalories);
  if (targetProtein !== undefined) db.targetProtein = Number(targetProtein);
  writeDb(db);
  res.json({ ok: true, targetCalories: db.targetCalories, targetProtein: db.targetProtein });
});

// Serve Flutter web build so GET / loads the site.
// Mount even if the directory doesn't exist yet; handle presence at request time.
const FRONT_DIR = path.join(__dirname, '..', 'front_end', 'app', 'build', 'web');
app.use(express.static(FRONT_DIR));
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api')) return next();
  const indexPath = path.join(FRONT_DIR, 'index.html');
  if (fs.existsSync(indexPath)) return res.sendFile(indexPath);
  return res.status(404).send('Frontend build not found. Run: cd front_end/app && flutter build web');
});

app.listen(PORT, () => {
  console.log(`NutriBoom backend listening on http://localhost:${PORT}`);
});
