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
