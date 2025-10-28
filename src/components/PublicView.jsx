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
