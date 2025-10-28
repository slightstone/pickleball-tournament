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
