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
