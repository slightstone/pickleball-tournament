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
