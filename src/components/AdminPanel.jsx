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
