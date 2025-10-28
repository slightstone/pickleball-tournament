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
