export function buildUpiLink({ vpa, name = '', amount, note = '' }) {
  const params = new URLSearchParams({
    pa: vpa,
    pn: name || vpa,
    cu: 'INR',
  });
  if (amount && Number(amount) > 0) {
    params.set('am', String(Number(amount).toFixed(2)));
  }
  if (note) params.set('tn', note);
  return `upi://pay?${params.toString()}`;
}
