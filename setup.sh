#!/usr/bin/env bash
set -euo pipefail

mkdir -p .github/workflows
mkdir -p src/components
mkdir -p src/styles
mkdir -p src/utils

# 404.html
cat > 404.html <<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Redirecting...</title>
    <meta http-equiv="refresh" content="0; url=/pickleball-tournament/">
    <script>
      // SPA fallback for GitHub Pages
      const path = location.pathname.replace(/\\/+/, "/");
      if (!path.startsWith("/pickleball-tournament")) {
        location.replace("/pickleball-tournament/");
      }
    </script>
  </head>
  <body></body>
</html>
EOF

# index.html
cat > index.html <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no"
    />
    <title>Pickleball Tournament Manager</title>
  </head>
  <body class="bg-gray-100">
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# netlify.toml (optional Netlify)
cat > netlify.toml <<'EOF'
[build]
  command = "npm run build"
  publish = "dist"

[dev]
  command = "vite"
  port = 5173
EOF

# package.json
cat > package.json <<'EOF'
{
  "name": "pickleball-tournament-manager",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "papaparse": "^5.4.1",
    "sql.js": "^1.9.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.4",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31",
    "tailwindcss": "^3.4.4",
    "vite": "^5.0.8"
  }
}
EOF

# postcss.config.js
cat > postcss.config.js <<'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {}
  }
};
EOF

# tailwind.config.js
cat > tailwind.config.js <<'EOF'
export default {
  content: ["./index.html", "./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        courtAvailable: "#22c55e", // green
        courtInPlay: "#eab308", // yellow
        courtWaiting: "#ef4444" // red
      }
    }
  },
  plugins: []
};
EOF

# vite.config.js
cat > vite.config.js <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => ({
  plugins: [react()],
  server: {
    port: 5173
  },
  // Use root in dev/preview, subpath on production builds for GitHub Pages
  // Adjusted for repo name: pickleball-tournament
  base: mode === "production" ? "/pickleball-tournament/" : "/"
}));
EOF

# README.md
cat > README.md <<'EOF'
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
EOF

# .github/workflows/deploy.yml
cat > .github/workflows/deploy.yml <<'EOF'
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 18
          cache: "npm"

      - name: Create .env from secret (with default)
        env:
          VITE_ADMIN_PASSWORD: ${{ secrets.VITE_ADMIN_PASSWORD }}
        run: |
          echo "VITE_ADMIN_PASSWORD=${VITE_ADMIN_PASSWORD:-admin123}" > .env

      - name: Install dependencies
        run: npm install

      - name: Build
        run: npm run build

      - name: Upload Pages Artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF

# src/main.jsx
cat > src/main.jsx <<'EOF'
import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App.jsx";
import "./styles/index.css";

const root = createRoot(document.getElementById("root"));
root.render(<App />);
EOF

# src/App.jsx
cat > src/App.jsx <<'EOF'
import React, { useEffect, useMemo, useState } from "react";
import AdminPanel from "./components/AdminPanel.jsx";
import PublicView from "./components/PublicView.jsx";
import { loadAppState, saveAppState } from "./utils/storage.js";

export default function App() {
  const [mode, setMode] = useState("public"); // "public" | "admin"
  const [passwordInput, setPasswordInput] = useState("");
  const adminPassword = import.meta.env.VITE_ADMIN_PASSWORD || "admin123";

  const [state, setState] = useState(() => {
    return (
      loadAppState() || {
        tournaments: [], // history
        currentTournament: null, // active tournament object
        playersCacheUpdatedAt: null
      }
    );
  });

  // persist to localStorage and notify other tabs
  useEffect(() => {
    saveAppState(state);
  }, [state]);

  // auto-refresh in public mode every 10s
  useEffect(() => {
    if (mode !== "public") return;
    const interval = setInterval(() => {
      const latest = loadAppState();
      if (latest) setState(latest);
    }, 10000);
    return () => clearInterval(interval);
  }, [mode]);

  // listen to localStorage events from other tabs
  useEffect(() => {
    function onStorage(e) {
      if (e.key === "ptm_app_state" && e.newValue) {
        try {
          const latest = JSON.parse(e.newValue);
          setState(latest);
        } catch {}
      }
    }
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, []);

  const handleLogin = () => {
    if (passwordInput.trim() === adminPassword) {
      setMode("admin");
      setPasswordInput("");
    } else {
      alert("Incorrect admin password");
    }
  };

  const logout = () => setMode("public");

  return (
    <div className="max-w-5xl mx-auto p-3 sm:p-4">
      <header className="flex items-center justify-between mb-3">
        <h1 className="text-xl sm:text-2xl font-semibold">Pickleball Tournament Manager</h1>
        <div className="flex items-center gap-2">
          {mode === "admin" ? (
            <>
              <span className="text-sm text-gray-600">Admin</span>
              <button className="btn btn-secondary" onClick={logout}>Logout</button>
            </>
          ) : (
            <div className="flex items-center gap-2">
              <input
                type="password"
                placeholder="Admin password"
                className="input w-36 sm:w-48"
                value={passwordInput}
                onChange={(e) => setPasswordInput(e.target.value)}
              />
              <button className="btn btn-primary" onClick={handleLogin}>Login</button>
            </div>
          )}
        </div>
      </header>

      {mode === "admin" ? (
        <AdminPanel state={state} setState={setState} />
      ) : (
        <PublicView state={state} />
      )}
    </div>
  );
}
EOF

# src/styles/index.css
cat > src/styles/index.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Basic styles */
html, body, #root {
  height: 100%;
}

.section {
  @apply bg-white rounded-lg shadow-sm p-4;
}

.section-header {
  @apply flex items-center justify-between mb-2;
}

.btn {
  @apply inline-flex items-center justify-center rounded-md border border-transparent px-4 py-2 text-sm font-medium shadow-sm transition-colors;
}

.btn-primary {
  @apply bg-blue-600 text-white hover:bg-blue-700;
}

.btn-secondary {
  @apply bg-gray-200 text-gray-900 hover:bg-gray-300;
}

.input {
  @apply w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500;
}

.select {
  @apply w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500;
}

.badge {
  @apply inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium;
}
EOF

# src/components/AdminPanel.jsx
cat > src/components/AdminPanel.jsx <<'EOF'
import React, { useEffect, useMemo, useState } from "react";
import { generateBracket, advanceWinner, assignMatchToCourt, endMatch } from "../utils/bracket.js";
import BracketView from "./BracketView.jsx";
import CourtControls from "./CourtControls.jsx";
import MatchLog from "./MatchLog.jsx";
import SignupPage from "./SignupPage.jsx";
import CheckInPanel from "./CheckInPanel.jsx";
import {
  getDb,
  listPlayers,
  addPlayer,
  importPlayers,
  saveTournamentSummary,
  listCheckedIn
} from "../utils/db.js";
import Papa from "papaparse";

const defaultCourts = ["Front Left", "Front Right", "Back"];

export default function AdminPanel({ state, setState }) {
  const [dbReady, setDbReady] = useState(false);
  const [players, setPlayers] = useState([]);
  const [form, setForm] = useState({
    name: "",
    date: new Date().toISOString().slice(0, 10),
    format: "single",
    targetType: "points",
    targetValue: 11,
    courts: defaultCourts
  });

  useEffect(() => {
    (async () => {
      await getDb();
      setDbReady(true);
      setPlayers(listPlayers());
    })();
  }, []);

  function createTournament() {
    // Use checked-in signups for the selected date as the entry list.
    const checkedIn = listCheckedIn(form.date);
    const teams = checkedIn.map((p) => p.name); // simple: singles as teams of 1 for now
    if (teams.length < 2) {
      alert("Need at least 2 checked-in players to create a tournament.");
      return;
    }
    const bracket = generateBracket({ format: form.format, teams });
    const tournament = {
      tournament: form.name || "Tournament",
      date: form.date,
      format: form.format,
      targetType: form.targetType,
      targetValue: Number(form.targetValue),
      courts: form.courts,
      rounds: bracket.rounds,
      log: []
    };
    setState({ ...state, currentTournament: tournament });
  }

  function updateCurrentTournament(next) {
    setState({ ...state, currentTournament: next });
  }

  function assign(matchId, courtName) {
    const next = { ...state.currentTournament };
    next.rounds = assignMatchToCourt({ rounds: next.rounds }, matchId, courtName).rounds;
    updateCurrentTournament(next);
  }

  function finish(matchId) {
    const scoreStr = prompt("Enter score (e.g., 11-7 or 5-3):");
    const winnerName = prompt("Winner name exactly as listed:");
    if (!winnerName) return;
    const nextBracket = endMatch({ rounds: state.currentTournament.rounds }, matchId, scoreStr, winnerName);
    const advanced = advanceWinner(nextBracket, matchId, winnerName);
    const next = { ...state.currentTournament, rounds: advanced.rounds };
    next.log = [
      { ts: Date.now(), matchId, winner: winnerName, score: scoreStr },
      ...(state.currentTournament.log || [])
    ];
    updateCurrentTournament(next);
  }

  function addCourt() {
    setForm((f) => ({ ...f, courts: [...f.courts, `Court ${f.courts.length + 1}`] }));
  }

  function removeCourt(i) {
    setForm((f) => ({ ...f, courts: f.courts.filter((_, idx) => idx !== i) }));
  }

  function handleCSVImport() {
    const url = prompt("Enter Google Sheet 'Publish to the web' CSV URL:");
    if (!url) return;
    fetch(url)
      .then((r) => r.text())
      .then((text) => {
        const parsed = Papa.parse(text, { header: false });
        const names = parsed.data
          .map((row) => (Array.isArray(row) ? row[0] : null))
          .filter((v) => typeof v === "string" && v.trim().length > 0);
        importPlayers(names);
        setPlayers(listPlayers());
        alert(`Imported ${names.length} players.`);
      })
      .catch((e) => alert("Failed to load CSV: " + e.message));
  }

  function addPlayerManual() {
    const name = prompt("Player name:");
    if (!name) return;
    addPlayer({ name });
    setPlayers(listPlayers());
  }

  function completeAndSaveSummary() {
    const t = state.currentTournament;
    if (!t) return;
    saveTournamentSummary({
      name: t.tournament,
      date: t.date,
      format: t.format,
      courts: t.courts,
      summary: {
        rounds: t.rounds,
        log: t.log
      }
    });
    alert("Tournament summary saved to local database.");
  }

  const activeMatches = useMemo(() => {
    const list = [];
    const t = state.currentTournament;
    if (!t) return list;
    for (const r of t.rounds) {
      for (const m of r.matches) {
        if (m.status === "in_play") list.push(m);
      }
    }
    return list;
  }, [state.currentTournament]);

  return (
    <div className="space-y-4">
      <div className="section">
        <div className="section-header">
          <h2 className="font-semibold">Tournament Setup</h2>
          <div className="flex gap-2">
            <button className="btn btn-secondary" onClick={handleCSVImport}>Import Players from Google Sheet CSV</button>
            <button className="btn btn-secondary" onClick={addPlayerManual}>Add Player</button>
          </div>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="text-sm text-gray-600">Name</label>
            <input className="input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          </div>
          <div>
            <label className="text-sm text-gray-600">Date</label>
            <input type="date" className="input" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} />
          </div>
          <div>
            <label className="text-sm text-gray-600">Format</label>
            <select className="select" value={form.format} onChange={(e) => setForm({ ...form, format: e.target.value })}>
              <option value="single">Single Elimination</option>
              <option value="double">Double Elimination (simplified)</option>
              <option value="round_robin">Round Robin</option>
              <option value="seeding">Seeding then Main</option>
            </select>
          </div>
          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="text-sm text-gray-600">Target Type</label>
              <select
                className="select"
                value={form.targetType}
                onChange={(e) => setForm({ ...form, targetType: e.target.value })}
              >
                <option value="points">Points</option>
                <option value="time">Time (minutes)</option>
              </select>
            </div>
            <div>
              <label className="text-sm text-gray-600">Target Value</label>
              <input
                className="input"
                type="number"
                min="1"
                value={form.targetValue}
                onChange={(e) => setForm({ ...form, targetValue: e.target.value })}
              />
            </div>
          </div>
        </div>
        <div className="mt-3">
          <div className="flex items-center justify-between">
            <h3 className="font-medium">Courts</h3>
            <button className="btn btn-secondary" onClick={addCourt}>Add Court</button>
          </div>
          <div className="flex flex-wrap gap-2 mt-2">
            {form.courts.map((c, idx) => (
              <span key={idx} className="badge bg-gray-200">
                {c}
                <button className="ml-2 text-gray-600" onClick={() => removeCourt(idx)}>✕</button>
              </span>
            ))}
          </div>
        </div>
        <div className="mt-3">
          <button className="btn btn-primary" onClick={createTournament} disabled={!dbReady}>
            Create Tournament (checked-in players will be used)
          </button>
        </div>
      </div>

      <div className="section">
        <div className="section-header">
          <h2 className="font-semibold">Check-In</h2>
        </div>
        <CheckInPanel date={form.date} onDateChange={(d) => setForm((f) => ({ ...f, date: d }))} />
      </div>

      {state.currentTournament && (
        <>
          <div className="section">
            <div className="section-header">
              <h2 className="font-semibold">Bracket View</h2>
              <button className="btn btn-secondary" onClick={completeAndSaveSummary}>Save Summary</button>
            </div>
            <BracketView tournament={state.currentTournament} />
          </div>

          <div className="section">
            <div className="section-header">
              <h2 className="font-semibold">Court Controls</h2>
            </div>
            <CourtControls tournament={state.currentTournament} assign={assign} finish={finish} />
          </div>

          <div className="section">
            <div className="section-header">
              <h2 className="font-semibold">Match Log</h2>
            </div>
            <MatchLog logs={state.currentTournament.log || []} />
          </div>
        </>
      )}

      <div className="section">
        <div className="section-header">
          <h2 className="font-semibold">Signup Page (Public)</h2>
        </div>
        <SignupPage />
      </div>
    </div>
  );
}
EOF

# src/components/PublicView.jsx
cat > src/components/PublicView.jsx <<'EOF'
import React, { useEffect, useMemo, useState } from "react";
import BracketView from "./BracketView.jsx";
import SignupPage from "./SignupPage.jsx";
import { loadAppState } from "../utils/storage.js";

export default function PublicView({ state }) {
  const [local, setLocal] = useState(state);
  const [tab, setTab] = useState("live"); // "live" | "signup"

  useEffect(() => setLocal(state), [state]);

  // auto-refresh each 10 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      const latest = loadAppState();
      if (latest) setLocal(latest);
    }, 10000);
    return () => clearInterval(interval);
  }, []);

  const activeMatches = useMemo(() => {
    const list = [];
    const t = local.currentTournament;
    if (!t) return list;
    for (const r of t.rounds) {
      for (const m of r.matches) {
        if (m.status === "in_play") list.push(m);
      }
    }
    return list;
  }, [local]);

  return (
    <div className="space-y-4">
      <div className="section">
        <div className="flex items-center justify-between mb-3">
          <div className="inline-flex rounded-md overflow-hidden border">
            <button
              className={`px-3 py-2 text-sm ${tab === "live" ? "bg-blue-600 text-white" : "bg-white"}`}
              onClick={() => setTab("live")}
            >
              Live Bracket
            </button>
            <button
              className={`px-3 py-2 text-sm ${tab === "signup" ? "bg-blue-600 text-white" : "bg-white"}`}
              onClick={() => setTab("signup")}
            >
              Signup
            </button>
          </div>
          <button className="btn btn-secondary" onClick={() => setLocal(loadAppState() || local)}>
            Refresh
          </button>
        </div>

        {tab === "signup" ? (
          <SignupPage />
        ) : (
          <>
            <div className="section-header">
              <h2 className="font-semibold">Current Tournament</h2>
            </div>
            {!local.currentTournament ? (
              <div className="text-sm text-gray-600">No active tournament yet.</div>
            ) : (
              <>
                <div className="mb-3">
                  <div className="text-sm text-gray-700">
                    <span className="font-medium">{local.currentTournament.tournament}</span>{" "}
                    — {local.currentTournament.date} — Format: {formatLabel(local.currentTournament.format)}
                  </div>
                </div>

                {/* Active Matches */}
                <div className="mb-3">
                  <h3 className="font-medium mb-2">Active Matches</h3>
                  <div className="space-y-2">
                    {activeMatches.map((m) => (
                      <div key={m.id} className="border rounded p-2 bg-yellow-50">
                        <div className="flex justify-between">
                          <span>Match #{m.id}</span>
                          <span className="text-gray-600">Court: {m.court}</span>
                        </div>
                        <div className="mt-1">{m.team1} vs {m.team2}</div>
                      </div>
                    ))}
                    {activeMatches.length === 0 && (
                      <div className="text-sm text-gray-600">No active matches at the moment.</div>
                    )}
                  </div>
                </div>

                <BracketView tournament={local.currentTournament} />
              </>
            )}
          </>
        )}
      </div>
    </div>
  );
}

function formatLabel(f) {
  if (f === "single") return "Single Elimination";
  if (f === "double") return "Double Elimination (simplified)";
  if (f === "round_robin") return "Round Robin";
  if (f === "seeding") return "Seeding then Main";
  return f;
}
EOF

# src/components/BracketView.jsx
cat > src/components/BracketView.jsx <<'EOF'
import React from "react";

export default function BracketView({ tournament }) {
  const { rounds } = tournament;
  return (
    <div className="overflow-x-auto">
      <div className="flex gap-4">
        {rounds.map((round) => (
          <div key={round.round} className="min-w-[220px]">
            <h3 className="font-medium mb-2">Round {round.round}</h3>
            <div className="space-y-2">
              {round.matches.map((m) => (
                <div key={m.id} className="border rounded p-2">
                  <div className="text-sm">
                    <div className="flex justify-between">
                      <span>Match #{m.id}</span>
                      <span className="text-gray-600">{statusLabel(m)}</span>
                    </div>
                    <div className="mt-1">
                      <div>{m.team1 || "TBD"}</div>
                      <div>{m.team2 || "TBD"}</div>
                    </div>
                    {m.court && (
                      <div className="mt-1 text-xs text-gray-700">Court: {m.court}</div>
                    )}
                    {m.winner && (
                      <div className="mt-1 text-xs">Winner: <span className="font-medium">{m.winner}</span> {m.score ? `(${m.score})` : ""}</div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function statusLabel(m) {
  if (m.status === "in_play") return "In Play";
  if (m.status === "done") return "Finished";
  return "Pending";
}
EOF

# src/components/CourtControls.jsx
cat > src/components/CourtControls.jsx <<'EOF'
import React, { useMemo } from "react";

export default function CourtControls({ tournament, assign, finish }) {
  const courtsState = useMemo(() => {
    const usage = Object.fromEntries(tournament.courts.map((c) => [c, null]));
    for (const r of tournament.rounds) {
      for (const m of r.matches) {
        if (m.court) usage[m.court] = m;
      }
    }
    return usage;
  }, [tournament]);

  const pendingMatches = useMemo(() => {
    const list = [];
    for (const r of tournament.rounds) {
      for (const m of r.matches) {
        if (m.status === "pending" && m.team1 && m.team2) list.push(m);
      }
    }
    return list;
  }, [tournament]);

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
      <div>
        <h4 className="font-medium mb-2">Courts</h4>
        <div className="space-y-2">
          {tournament.courts.map((c) => {
            const m = courtsState[c];
            const status = m ? "in_play" : "available";
            return (
              <div key={c} className="border rounded p-2">
                <div className="flex items-center justify-between">
                  <span className="font-medium">{c}</span>
                  <span
                    className={`badge ${statusBadgeClass(status)}`}
                    title={status === "in_play" ? `Match #${m.id}` : "Available"}
                  >
                    {status === "in_play" ? "In Play" : "Available"}
                  </span>
                </div>
                {m && (
                  <div className="mt-2 text-sm">
                    <div>{m.team1} vs {m.team2}</div>
                    <div className="mt-2 flex gap-2">
                      <button className="btn btn-primary" onClick={() => finish(m.id)}>End Match</button>
                    </div>
                  </div>
                )}
                {!m && (
                  <div className="mt-2">
                    <select
                      className="select"
                      onChange={(e) => {
                        const matchId = Number(e.target.value);
                        if (matchId) assign(matchId, c);
                        e.target.value = "";
                      }}
                      defaultValue=""
                    >
                      <option value="" disabled>
                        Assign pending match...
                      </option>
                      {pendingMatches.map((pm) => (
                        <option key={pm.id} value={pm.id}>
                          Match #{pm.id}: {pm.team1} vs {pm.team2}
                        </option>
                      ))}
                    </select>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
      <div>
        <h4 className="font-medium mb-2">Active Matches</h4>
        <div className="space-y-2">
          {Object.values(courtsState)
            .filter(Boolean)
            .map((m) => (
              <div key={m.id} className="border rounded p-2">
                <div className="text-sm">
                  <div className="flex justify-between">
                    <span>Match #{m.id}</span>
                    <span className="text-gray-600">Court: {m.court}</span>
                  </div>
                  <div className="mt-1">{m.team1} vs {m.team2}</div>
                  <div className="mt-2">
                    <button className="btn btn-primary" onClick={() => finish(m.id)}>End Match</button>
                  </div>
                </div>
              </div>
            ))}
          {Object.values(courtsState).filter(Boolean).length === 0 && (
            <div className="text-sm text-gray-600">No active matches.</div>
          )}
        </div>
      </div>
    </div>
  );
}

function statusBadgeClass(status) {
  if (status === "available") return "bg-courtAvailable text-white";
  if (status === "in_play") return "bg-courtInPlay text-white";
  return "bg-courtWaiting text-white";
}
EOF

# src/components/MatchLog.jsx
cat > src/components/MatchLog.jsx <<'EOF'
import React from "react";

export default function MatchLog({ logs }) {
  if (!logs || logs.length === 0) {
    return <div className="text-sm text-gray-600">No matches recorded yet.</div>;
  }
  return (
    <ul className="space-y-2">
      {logs.map((l, idx) => (
        <li key={idx} className="border rounded p-2 text-sm">
          <div className="flex justify-between">
            <span>Match #{l.matchId}</span>
            <span className="text-gray-600">{new Date(l.ts).toLocaleTimeString()}</span>
          </div>
          <div className="mt-1">
            Winner: <span className="font-medium">{l.winner}</span>{l.score ? ` (${l.score})` : ""}
          </div>
        </li>
      ))}
    </ul>
  );
}
EOF

# src/components/SignupPage.jsx
cat > src/components/SignupPage.jsx <<'EOF'
import React, { useEffect, useState } from "react";
import { getDb, addSignup, listSignups, isSignupClosed } from "../utils/db.js";

export default function SignupPage() {
  const [ready, setReady] = useState(false);
  const [date, setDate] = useState(nextSaturday());
  const [name, setName] = useState("");
  const [contact, setContact] = useState("");
  const [skill, setSkill] = useState(2);
  const [list, setList] = useState([]);
  const [closed, setClosed] = useState(false);

  useEffect(() => {
    (async () => {
      await getDb();
      setReady(true);
      load(date);
    })();
  }, []);

  function load(d) {
    setList(listSignups(d));
    setClosed(isSignupClosed(d));
  }

  function submit(e) {
    e.preventDefault();
    if (!name.trim()) return;
    if (closed) {
      alert("Signup is closed for this date.");
      return;
    }
    addSignup({ name: name.trim(), contact: contact.trim(), tournament_date: date, skill });
    setName("");
    setContact("");
    setSkill(2);
    load(date);
  }

  return (
    <div>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <form onSubmit={submit} className="space-y-2">
          <div>
            <label className="text-sm text-gray-600">Tournament Date</label>
            <input
              type="date"
              className="input"
              value={date}
              onChange={(e) => {
                setDate(e.target.value);
                load(e.target.value);
              }}
            />
          </div>
          <div>
            <label className="text-sm text-gray-600">Player Name</label>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="Your name" />
          </div>
          <div>
            <label className="text-sm text-gray-600">Contact (optional)</label>
            <input className="input" value={contact} onChange={(e) => setContact(e.target.value)} placeholder="Phone or email" />
          </div>
          <div>
            <label className="text-sm text-gray-600">Skill (1–4)</label>
            <select className="select" value={skill} onChange={(e) => setSkill(Number(e.target.value))}>
              <option value={1}>1 - Beginner</option>
              <option value={2}>2 - Casual</option>
              <option value={3}>3 - Intermediate</option>
              <option value={4}>4 - Advanced</option>
            </select>
          </div>
          <button className="btn btn-primary" type="submit" disabled={!ready || closed}>
            {closed ? "Signup Closed" : "Sign Up"}
          </button>
        </form>
        <div>
          <h4 className="font-medium mb-2">Signed Up ({list.length})</h4>
          {closed && <div className="mb-2 text-xs text-red-600">Signup is closed for this date.</div>}
          <ul className="space-y-1">
            {list.map((s) => (
              <li key={s.id} className="text-sm border rounded p-2">
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-medium">{s.name}</div>
                    {s.contact && <div className="text-gray-600">{s.contact}</div>}
                  </div>
                  <span className="badge bg-gray-200">Skill {s.skill ?? 2}</span>
                </div>
              </li>
            ))}
            {list.length === 0 && <div className="text-sm text-gray-600">No signups yet.</div>}
          </ul>
        </div>
      </div>
    </div>
  );
}

function nextSaturday() {
  const d = new Date();
  const day = d.getDay(); // 0=Sun ... 6=Sat
  const diff = (6 - day + 7) % 7 || 7;
  const next = new Date(d.getFullYear(), d.getMonth(), d.getDate() + diff);
  return next.toISOString().slice(0, 10);
}
EOF

# src/components/CheckInPanel.jsx
cat > src/components/CheckInPanel.jsx <<'EOF'
import React, { useEffect, useState } from "react";
import {
  getDb,
  listSignups,
  updateSignupCheckin,
  updateSignupSkill,
  isSignupClosed,
  setSignupClosed
} from "../utils/db.js";

export default function CheckInPanel({ date, onDateChange }) {
  const [ready, setReady] = useState(false);
  const [d, setD] = useState(date);
  const [list, setList] = useState([]);
  const [filter, setFilter] = useState("");
  const [closed, setClosedState] = useState(false);

  useEffect(() => {
    (async () => {
      await getDb();
      setReady(true);
      const initialDate = date || new Date().toISOString().slice(0, 10);
      setD(initialDate);
      load(initialDate);
    })();
  }, []);

  useEffect(() => {
    if (date && date !== d) {
      setD(date);
      load(date);
    }
  }, [date]);

  function load(dateStr) {
    setList(listSignups(dateStr));
    setClosedState(isSignupClosed(dateStr));
  }

  function toggleCheckIn(id, next) {
    updateSignupCheckin(id, next);
    load(d);
  }

  function changeSkill(id, skill) {
    updateSignupSkill(id, Number(skill));
    load(d);
  }

  function handleDateChange(nextDate) {
    setD(nextDate);
    load(nextDate);
    if (onDateChange) onDateChange(nextDate);
  }

  function toggleClosed() {
    const next = !closed;
    setSignupClosed(d, next);
    setClosedState(next);
  }

  const filtered = list.filter((s) =>
    s.name.toLowerCase().includes(filter.toLowerCase())
  );

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <label className="text-sm text-gray-600">Date</label>
          <input
            type="date"
            className="input"
            value={d}
            onChange={(e) => handleDateChange(e.target.value)}
          />
        </div>
        <div className="flex items-center gap-2">
          <span className="text-sm">Signup {closed ? "Closed" : "Open"}</span>
          <button className="btn btn-secondary" onClick={toggleClosed}>
            {closed ? "Open Signup" : "Close Signup"}
          </button>
        </div>
      </div>

      <div className="flex items-center gap-2 mb-2">
        <input
          className="input"
          placeholder="Filter by name..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        />
        <span className="text-xs text-gray-600">
          Checked In: {list.filter((s) => s.checked_in).length}/{list.length}
        </span>
      </div>

      <ul className="space-y-2">
        {filtered.map((s) => (
          <li key={s.id} className="border rounded p-2 text-sm">
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 items-center">
              <div className="font-medium">{s.name}</div>
              <div className="text-gray-600">{s.contact}</div>
              <div className="flex items-center gap-2">
                <label className="text-xs text-gray-600">Skill</label>
                <select
                  className="select"
                  value={s.skill ?? 2}
                  onChange={(e) => changeSkill(s.id, e.target.value)}
                >
                  <option value={1}>1</option>
                  <option value={2}>2</option>
                  <option value={3}>3</option>
                  <option value={4}>4</option>
                </select>
              </div>
              <div className="flex items-center gap-2">
                <label className="text-xs text-gray-600">Checked In</label>
                <input
                  type="checkbox"
                  checked={!!s.checked_in}
                  onChange={(e) => toggleCheckIn(s.id, e.target.checked)}
                />
              </div>
            </div>
          </li>
        ))}
        {filtered.length === 0 && (
          <li className="text-sm text-gray-600">No signups for this date.</li>
        )}
      </ul>
    </div>
  );
}
EOF

# src/components/Public-only components (MatchLog is above)

# src/utils/storage.js
cat > src/utils/storage.js <<'EOF'
const KEY = "ptm_app_state";

export function loadAppState() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function saveAppState(state) {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
  } catch {}
}
EOF

# src/utils/bracket.js
cat > src/utils/bracket.js <<'EOF'
/**
 * Generate bracket structure for various formats.
 * Returns { rounds: [{ round, matches: [{id, team1, team2, court: null, winner: null, status: "pending"}]}] }
 */

export function generateBracket({ format, teams }) {
  if (format === "single") return generateSingleElim(teams);
  if (format === "double") return generateDoubleElimSimplified(teams);
  if (format === "round_robin") return generateRoundRobin(teams);
  if (format === "seeding") return generateSeedingThenMain(teams);
  return { rounds: [] };
}

function generateSingleElim(teams) {
  const teamNames = teams.slice();
  const numTeams = nextPowerOfTwo(teamNames.length);
  while (teamNames.length < numTeams) teamNames.push(null); // byes
  let matches = [];
  for (let i = 0; i < teamNames.length; i += 2) {
    matches.push({
      id: i / 2 + 1,
      team1: teamNames[i],
      team2: teamNames[i + 1],
      court: null,
      winner: null,
      status: "pending",
      score: null
    });
  }
  const rounds = [];
  let roundIndex = 1;
  rounds.push({ round: roundIndex++, matches });
  let prevRound = matches;
  while (prevRound.length > 1) {
    const nextRoundMatches = [];
    for (let i = 0; i < prevRound.length; i += 2) {
      nextRoundMatches.push({
        id: rounds.reduce((acc, r) => acc + r.matches.length, 0) + nextRoundMatches.length + 1,
        team1: null,
        team2: null,
        court: null,
        winner: null,
        status: "pending",
        score: null
      });
    }
    rounds.push({ round: roundIndex++, matches: nextRoundMatches });
    prevRound = nextRoundMatches;
  }
  return { rounds };
}

function generateRoundRobin(teams) {
  const validTeams = teams.filter(Boolean);
  const rounds = [];
  const pairings = [];
  for (let i = 0; i < validTeams.length; i++) {
    for (let j = i + 1; j < validTeams.length; j++) {
      pairings.push([validTeams[i], validTeams[j]]);
    }
  }
  let id = 1;
  // Batch pairings into rounds with up to N matches per round
  const perRound = Math.ceil(validTeams.length / 2);
  for (let i = 0; i < pairings.length; i += perRound) {
    const batch = pairings.slice(i, i + perRound).map(([a, b]) => ({
      id: id++,
      team1: a,
      team2: b,
      court: null,
      winner: null,
      status: "pending",
      score: null
    }));
    rounds.push({ round: rounds.length + 1, matches: batch });
  }
  return { rounds };
}

function generateDoubleElimSimplified(teams) {
  // Simplified: generate single elim and track losses count per team externally
  return generateSingleElim(teams);
}

function generateSeedingThenMain(teams) {
  // Simple approach: seed teams by provided order into single elim
  return generateSingleElim(teams);
}

export function advanceWinner(bracket, matchId, winnerName) {
  // Find match and set winner, then propagate to next round
  const rounds = bracket.rounds.map((r) => ({
    ...r,
    matches: r.matches.map((m) => ({ ...m }))
  }));
  let targetRoundIndex = -1;
  let idxInRound = -1;
  for (let r = 0; r < rounds.length; r++) {
    const i = rounds[r].matches.findIndex((m) => m.id === matchId);
    if (i !== -1) {
      targetRoundIndex = r;
      idxInRound = i;
      break;
    }
  }
  if (targetRoundIndex === -1) return { rounds }; // not found

  const match = rounds[targetRoundIndex].matches[idxInRound];
  match.winner = winnerName;
  match.status = "done";
  // Determine next round slot
  if (targetRoundIndex < rounds.length - 1) {
    const nextRound = rounds[targetRoundIndex + 1];
    const nextIdx = Math.floor(idxInRound / 2);
    const nextMatch = nextRound.matches[nextIdx];
    if (idxInRound % 2 === 0) {
      nextMatch.team1 = winnerName;
    } else {
      nextMatch.team2 = winnerName;
    }
  }
  return { rounds };
}

export function assignMatchToCourt(bracket, matchId, courtName) {
  const rounds = bracket.rounds.map((r) => ({
    ...r,
    matches: r.matches.map((m) => ({ ...m }))
  }));
  for (const round of rounds) {
    for (const match of round.matches) {
      if (match.id === matchId) {
        match.court = courtName;
        match.status = "in_play";
      }
    }
  }
  return { rounds };
}

export function endMatch(bracket, matchId, score, winnerName) {
  const rounds = bracket.rounds.map((r) => ({
    ...r,
    matches: r.matches.map((m) => ({ ...m }))
  }));
  for (const round of rounds) {
    for (const match of round.matches) {
      if (match.id === matchId) {
        match.score = score;
        match.winner = winnerName;
        match.status = "done";
        match.court = null;
      }
    }
  }
  return { rounds };
}

function nextPowerOfTwo(n) {
  let p = 1;
  while (p < n) p <<= 1;
  return p;
}
EOF

# src/utils/db.js
cat > src/utils/db.js <<'EOF'
import initSqlJs from "sql.js";

let SQL = null;
let db = null;

// Persist DB to localStorage
const DB_KEY = "ptm_sqlite_db";

function loadDbFromStorage() {
  try {
    const base64 = localStorage.getItem(DB_KEY);
    if (!base64) return null;
    const binary = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
    return new SQL.Database(binary);
  } catch {
    return null;
  }
}

function saveDbToStorage() {
  try {
    const data = db.export();
    const base64 = btoa(String.fromCharCode(...data));
    localStorage.setItem(DB_KEY, base64);
  } catch {}
}

export async function getDb() {
  if (db) return db;
  if (!SQL) {
    SQL = await initSqlJs({
      locateFile: (file) => `https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.9.0/${file}`
    });
  }
  db = loadDbFromStorage();
  if (!db) {
    db = new SQL.Database();
    bootstrapSchema();
    saveDbToStorage();
  } else {
    // Ensure schema upgrades are applied on existing DBs
    upgradeSchema();
    saveDbToStorage();
  }
  return db;
}

function bootstrapSchema() {
  db.run(`
    CREATE TABLE IF NOT EXISTS players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      rating REAL,
      notes TEXT
    );
    CREATE TABLE IF NOT EXISTS signups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      contact TEXT,
      tournament_date TEXT NOT NULL,
      skill INTEGER DEFAULT 2,
      checked_in INTEGER DEFAULT 0
    );
    CREATE TABLE IF NOT EXISTS tournaments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      date TEXT NOT NULL,
      format TEXT NOT NULL,
      courts_json TEXT NOT NULL,
      summary_json TEXT
    );
  `);
}

function upgradeSchema() {
  try { db.run(`ALTER TABLE signups ADD COLUMN skill INTEGER DEFAULT 2`); } catch {}
  try { db.run(`ALTER TABLE signups ADD COLUMN checked_in INTEGER DEFAULT 0`); } catch {}
}

// Players
export function listPlayers() {
  const res = db.exec("SELECT id, name, rating, notes FROM players ORDER BY name ASC");
  const rows = res[0]?.values || [];
  return rows.map(([id, name, rating, notes]) => ({ id, name, rating, notes }));
}

export function addPlayer({ name, rating = null, notes = "" }) {
  const stmt = db.prepare("INSERT INTO players (name, rating, notes) VALUES (?, ?, ?)");
  stmt.run([name, rating, notes]);
  stmt.free();
  saveDbToStorage();
}

export function importPlayers(names = []) {
  db.run("BEGIN TRANSACTION");
  try {
    const stmt = db.prepare("INSERT INTO players (name) VALUES (?)");
    for (const name of names) {
      if (!name) continue;
      stmt.run([name.trim()]);
    }
    stmt.free();
    db.run("COMMIT");
    saveDbToStorage();
  } catch (e) {
    db.run("ROLLBACK");
    throw e;
  }
}

// Signups
export function listSignups(dateStr) {
  const stmt = db.prepare(
    "SELECT id, name, contact, tournament_date, skill, checked_in FROM signups WHERE tournament_date = ? ORDER BY name ASC"
  );
  stmt.bind([dateStr]);
  const out = [];
  while (stmt.step()) {
    const row = stmt.getAsObject();
    out.push({
      id: row.id,
      name: row.name,
      contact: row.contact,
      tournament_date: row.tournament_date,
      skill: Number(row.skill || 2),
      checked_in: Number(row.checked_in || 0) === 1
    });
  }
  stmt.free();
  return out;
}

export function addSignup({ name, contact = "", tournament_date, skill = 2 }) {
  const stmt = db.prepare("INSERT INTO signups (name, contact, tournament_date, skill, checked_in) VALUES (?, ?, ?, ?, ?)");
  stmt.run([name, contact, tournament_date, Number(skill || 2), 0]);
  stmt.free();
  saveDbToStorage();
}

export function updateSignupCheckin(id, checkedIn) {
  const stmt = db.prepare("UPDATE signups SET checked_in = ? WHERE id = ?");
  stmt.run([checkedIn ? 1 : 0, id]);
  stmt.free();
  saveDbToStorage();
}

export function updateSignupSkill(id, skill) {
  const stmt = db.prepare("UPDATE signups SET skill = ? WHERE id = ?");
  stmt.run([Number(skill || 2), id]);
  stmt.free();
  saveDbToStorage();
}

export function listCheckedIn(dateStr) {
  const stmt = db.prepare(
    "SELECT id, name, contact, tournament_date, skill FROM signups WHERE tournament_date = ? AND checked_in = 1 ORDER BY name ASC"
  );
  stmt.bind([dateStr]);
  const out = [];
  while (stmt.step()) {
    const row = stmt.getAsObject();
    out.push({
      id: row.id,
      name: row.name,
      contact: row.contact,
      tournament_date: row.tournament_date,
      skill: Number(row.skill || 2)
    });
  }
  stmt.free();
  return out;
}

// Signup open/closed per date (stored in localStorage for simplicity)
const SIGNUP_CLOSED_KEY = "ptm_signup_closed_by_date";

function loadSignupClosedMap() {
  try {
    return JSON.parse(localStorage.getItem(SIGNUP_CLOSED_KEY) || "{}");
  } catch {
    return {};
  }
}

function saveSignupClosedMap(map) {
  try {
    localStorage.setItem(SIGNUP_CLOSED_KEY, JSON.stringify(map));
  } catch {}
}

export function isSignupClosed(dateStr) {
  const map = loadSignupClosedMap();
  return !!map[dateStr];
}

export function setSignupClosed(dateStr, closed) {
  const map = loadSignupClosedMap();
  map[dateStr] = !!closed;
  saveSignupClosedMap(map);
}

// Tournaments
export function saveTournamentSummary({ name, date, format, courts, summary }) {
  const stmt = db.prepare("INSERT INTO tournaments (name, date, format, courts_json, summary_json) VALUES (?, ?, ?, ?, ?)");
  stmt.run([name, date, format, JSON.stringify(courts), JSON.stringify(summary || {})]);
  stmt.free();
  saveDbToStorage();
}

export function listTournaments() {
  const res = db.exec("SELECT id, name, date, format, courts_json, summary_json FROM tournaments ORDER BY date DESC");
  const rows = res[0]?.values || [];
  return rows.map(([id, name, date, format, courts_json, summary_json]) => ({
    id,
    name,
    date,
    format,
    courts: JSON.parse(courts_json),
    summary: summary_json ? JSON.parse(summary_json) : null
  }));
}

// Utility: duplicate signups from one date to another
export function duplicateSignups(fromDate, toDate) {
  const list = listSignups(fromDate);
  db.run("BEGIN TRANSACTION");
  try {
    const stmt = db.prepare("INSERT INTO signups (name, contact, tournament_date, skill, checked_in) VALUES (?, ?, ?, ?, ?)");
    for (const s of list) {
      stmt.run([s.name, s.contact || "", toDate, Number(s.skill || 2), 0]);
    }
    stmt.free();
    db.run("COMMIT");
    saveDbToStorage();
  } catch (e) {
    db.run("ROLLBACK");
    throw e;
  }
}
EOF