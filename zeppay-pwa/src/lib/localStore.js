const RECENTS_KEY = 'zeppay_recents';
const HISTORY_KEY = 'zeppay_history';
const PROFILE_KEY = 'zeppay_profile';
const COINS_KEY = 'zeppay_coins';
const COIN_LEDGER_KEY = 'zeppay_coin_ledger';
const REDEMPTIONS_KEY = 'zeppay_redemptions';
const REQUESTS_KEY = 'zeppay_requests';
const GROUPS_KEY = 'zeppay_groups';
const EXPENSES_KEY = 'zeppay_expenses';

function read(key, fallback) {
  try {
    return JSON.parse(localStorage.getItem(key) || JSON.stringify(fallback));
  } catch {
    return fallback;
  }
}

function write(key, value) {
  localStorage.setItem(key, JSON.stringify(value));
}

function uid() {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
}

export function loadRecents() {
  return read(RECENTS_KEY, []);
}

export function saveRecent(entry) {
  const list = loadRecents().filter((r) => r.vpa !== entry.vpa);
  list.unshift(entry);
  write(RECENTS_KEY, list.slice(0, 8));
}

export function loadHistory() {
  return read(HISTORY_KEY, []);
}

export function logPayment(entry) {
  const list = loadHistory();
  const row = { id: uid(), ...entry, at: new Date().toISOString() };
  list.unshift(row);
  write(HISTORY_KEY, list.slice(0, 100));
  if (entry.status === 'success-user' || entry.status === 'success') {
    awardCoinsForPayment(row);
  }
  return row;
}

export function loadProfile() {
  return read(PROFILE_KEY, { name: '', vpa: '', phone: '' });
}

export function saveProfile(profile) {
  write(PROFILE_KEY, profile);
}

export function loadCoinBalance() {
  return read(COINS_KEY, 0);
}

export function loadCoinLedger() {
  return read(COIN_LEDGER_KEY, []);
}

export function loadRedemptions() {
  return read(REDEMPTIONS_KEY, []);
}

function awardCoinsForPayment(payment) {
  const amount = Number(payment.amount) || 0;
  const coins = Math.floor(amount / 10);
  if (coins <= 0) return;
  const ledger = loadCoinLedger();
  if (ledger.some((e) => e.paymentId === payment.id)) return;
  ledger.unshift({
    paymentId: payment.id,
    coinsEarned: coins,
    amount,
    at: payment.at,
  });
  write(COIN_LEDGER_KEY, ledger.slice(0, 50));
  write(COINS_KEY, loadCoinBalance() + coins);
}

export function redeemPartner(brand) {
  const balance = loadCoinBalance();
  if (balance < brand.coinsRequired) return null;
  const code = `ZEP-${1000 + Math.floor(Math.random() * 9000)}-${1000 + Math.floor(Math.random() * 9000)}`;
  const redemption = {
    id: uid(),
    brandId: brand.id,
    brandName: brand.name,
    coinsSpent: brand.coinsRequired,
    voucherCode: code,
    at: new Date().toISOString(),
  };
  const redemptions = loadRedemptions();
  redemptions.unshift(redemption);
  write(REDEMPTIONS_KEY, redemptions.slice(0, 30));
  write(COINS_KEY, balance - brand.coinsRequired);
  return redemption;
}

export function loadRequests() {
  return read(REQUESTS_KEY, []);
}

export function addRequest(req) {
  const list = loadRequests();
  const row = { id: uid(), status: 'pending', createdAt: new Date().toISOString(), ...req };
  list.unshift(row);
  write(REQUESTS_KEY, list.slice(0, 40));
  return row;
}

export function updateRequest(id, status) {
  const list = loadRequests().map((r) => (r.id === id ? { ...r, status } : r));
  write(REQUESTS_KEY, list);
}

export function loadGroups() {
  return read(GROUPS_KEY, []);
}

export function saveGroup(group) {
  const list = loadGroups().filter((g) => g.id !== group.id);
  list.unshift(group);
  write(GROUPS_KEY, list.slice(0, 20));
}

export function loadExpenses() {
  return read(EXPENSES_KEY, []);
}

export function addExpense(expense) {
  const list = loadExpenses();
  list.unshift({ id: uid(), createdAt: new Date().toISOString(), ...expense });
  write(EXPENSES_KEY, list.slice(0, 60));
}

export function spendingSummary() {
  const success = loadHistory().filter(
    (h) => h.status === 'success-user' || h.status === 'success',
  );
  const total = success.reduce((sum, h) => sum + (Number(h.amount) || 0), 0);
  const byDay = {};
  for (const h of success) {
    const day = new Date(h.at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
    byDay[day] = (byDay[day] || 0) + (Number(h.amount) || 0);
  }
  return { total, count: success.length, byDay };
}
