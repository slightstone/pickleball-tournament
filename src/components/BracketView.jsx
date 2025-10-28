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
