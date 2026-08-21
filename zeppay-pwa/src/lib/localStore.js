const RECENTS_KEY = 'zeppay_recents';
const HISTORY_KEY = 'zeppay_history';

export function loadRecents() {
  try {
    return JSON.parse(localStorage.getItem(RECENTS_KEY) || '[]');
  } catch {
    return [];
  }
}

export function saveRecent(entry) {
  const list = loadRecents().filter((r) => r.vpa !== entry.vpa);
  list.unshift(entry);
  localStorage.setItem(RECENTS_KEY, JSON.stringify(list.slice(0, 8)));
}

export function loadHistory() {
  try {
    return JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]');
  } catch {
    return [];
  }
}

export function logPayment(entry) {
  const list = loadHistory();
  list.unshift({ ...entry, at: new Date().toISOString() });
  localStorage.setItem(HISTORY_KEY, JSON.stringify(list.slice(0, 50)));
}
