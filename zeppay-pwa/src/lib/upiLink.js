export function encodeVpaForUssd(vpa) {
  return vpa.replaceAll('.', '*').replaceAll('@', '*');
}

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

/** NPCI *99# send-to-UPI-ID with amount — works on some carriers via tel: */
export function buildUssdTelLink({ vpa, amount }) {
  const rupees = Math.round(Number(amount) || 0);
  const encoded = encodeVpaForUssd(vpa);
  return `tel:*99*1*3*${encoded}*${rupees}%23`;
}
