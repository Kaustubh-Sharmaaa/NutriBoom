# NutriBoom

Free, local-first setup with a simple backend and a Flutter app that also runs on the web.

## What’s Included
- Backend: Node.js + Express with a JSON file DB (`backend/`).
- Frontend: Flutter app (mobile/desktop/web) under `front_end/app` wired to the backend.
- Web: Run the Flutter app in Chrome or build static files for hosting.

## Prerequisites
- Node.js 18+ and npm
- Flutter 3.19+ (Dart SDK 3.3+)

## Backend (free, local)
1. Open `backend/` in a terminal:
   - `npm install`
   - `npm start`
2. The API serves on `http://localhost:3000` with these routes:
   - `GET /api/health` – quick check
   - `GET /api/consumed` – totals + entries
   - `GET /api/foods?q=` – search foods via USDA FoodData Central if `FDC_API_KEY` is set; otherwise uses a small built-in list
   - `POST /api/consume` – add an entry `{ name, calorie, protein }`
   - `DELETE /api/consume/:index` – remove entry by index
   - `POST /api/targets` – update `{ targetCalories, targetProtein }`

Data persists in `backend/data/db.json`.

### USDA FoodData Central (optional)
- Get an API key: https://fdc.nal.usda.gov/api-guide
- Put your key in `backend/.env` (this file is gitignored):
  - `echo "FDC_API_KEY=YOUR_KEY_HERE" > backend/.env`
- Start the app normally (`bash start_all.sh` or `cd backend && npm start`). The backend auto-loads `.env`.

## Frontend (Flutter)
From `front_end/app`:
- Install deps: `flutter pub get`
- Run on web: `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000`
- Run on iOS/desktop: `flutter run --dart-define=API_BASE_URL=http://localhost:3000`
- Android emulator needs host alias `10.0.2.2`:
  - `flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000`

The app shows calorie/protein gauges from backend totals and lets you search + add foods.

## Make a Website (free hosting options)
- Build static web files: `flutter build web --dart-define=API_BASE_URL=https://YOUR-BACKEND-URL`
- Output is in `front_end/app/build/web`.

Free hosting choices for the static site:
- GitHub Pages: push `build/web` to a `gh-pages` branch.
- Netlify: drag-and-drop the `build/web` folder.
- Cloudflare Pages: connect repo and set build output to `front_end/app/build/web`.

Free hosting choices for the backend API:
- Render free web service (Express). Use `npm start` and `PORT` env.
- Railway free tier.
- Fly.io (small shared VM) or Okteto.

Tip: When deploying web, set CORS to allow your site origin (backend already enables permissive CORS for dev).

## Config
The Flutter app reads `API_BASE_URL` from `--dart-define`. Defaults to `http://localhost:3000` for convenience.

## Project Structure
- `backend/` — Node/Express API and JSON DB
- `front_end/app/` — Flutter app (mobile + web)

## One-command Start
- Run: `bash start_all.sh`
- This builds the Flutter web app and starts the backend at `http://localhost:3000`.
- Open: `http://localhost:3000`

## Serve Frontend from Backend (optional)
- Build once: `cd front_end/app && flutter build web --dart-define=API_BASE_URL=http://localhost:3000`
- Start backend: `cd backend && npm start`
- Open `http://localhost:3000` — the backend serves the built web app and the APIs together.

## Future Enhancements (still free)
- Authentication (Supabase or Firebase free tier)
- Real food database API (e.g., USDA, Edamam; free tiers available)
- User profiles and per-user history
