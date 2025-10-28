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
