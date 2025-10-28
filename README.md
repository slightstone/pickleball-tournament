# Pickleball Tournament Manager

A mobile-first web app to run live 3-court pickleball tournaments. Includes:
- Admin panel for creating tournaments, assigning courts, recording winners
- Public read-only view of brackets and active courts
- Local persistence using in-browser SQLite (sql.js), stored in localStorage
- Player cache across weeks
- Google Sheet CSV player import
- Public signup page for upcoming tournaments
- Check-in panel for day-of toggles and skill adjustments

## Tech
- React + Vite + TailwindCSS
- sql.js (SQLite in the browser via WebAssembly)
- LocalStorage for app state sync across tabs/devices
- No user accounts. Single admin password from `.env`.

## Getting Started
1. Install dependencies:
   - `npm install`
2. Run dev:
   - `npm run dev`
3. Admin password:
   - Set `VITE_ADMIN_PASSWORD` in `.env` (default `admin123`)

## Usage
- Admin Mode:
  - Enter the admin password, then:
    - Import players from a Google Sheet CSV
      - In Google Sheets: File → Share → Publish to web → CSV
      - Copy the CSV URL and paste it in the app
      - The first column will be treated as the player name list
    - Add players manually
    - Use the Check-In panel:
      - Select the tournament date
      - Open/close signup
      - Toggle “Checked In” and adjust skill for each signup
    - Set tournament name, date, format, target (points or time), and courts
    - Create the tournament (uses checked-in players for that date)
    - Assign pending matches to courts
    - End matches with winner and score; bracket auto-advances
    - Save a summary to the local SQLite DB
- Public Mode:
  - Tabs: Live Bracket and Signup
  - Live Bracket shows current bracket and active matches
  - Signup shows the public signup form and list
  - Auto-refreshes every 10 seconds or via manual Refresh

- Signup Page:
  - Players can sign up for an upcoming tournament date
  - Everyone can see who already signed up
  - Signups are saved in the local SQLite DB

## Data Persistence
- Players, tournaments, and signups are stored in a local SQLite DB (sql.js) and saved to localStorage.
- App state (current tournament) is also stored in localStorage for basic sync/refresh behavior.

## Deployment

### GitHub Pages (repo name: `pickleball-tournament`)
- This project is preconfigured for the repo `slightstone/pickleball-tournament`.
- GitHub Pages URL will be: `https://<your-username>.github.io/pickleball-tournament/`
- The project is configured for GitHub Pages:
  - `vite.config.js` sets `base: "/pickleball-tournament/"`
  - `.github/workflows/deploy.yml` builds and deploys on push to `main`
  - `404.html` handles SPA fallback under `/pickleball-tournament/`
- Optional admin password via Actions secret:
  - Repo Settings → Secrets and variables → Actions → New secret
  - Name: `VITE_ADMIN_PASSWORD`, Value: your desired password

### Netlify (optional)
- Build command: `npm run build`
- Publish directory: `dist`

## Notes
- Double elimination is simplified in this version (uses single elimination bracket; losses tracking not fully implemented).
- Seeding uses input order for now.
- For multi-device live control across a venue, consider keeping one admin device as the source of truth and use public mode devices to view status.
