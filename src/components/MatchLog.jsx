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
