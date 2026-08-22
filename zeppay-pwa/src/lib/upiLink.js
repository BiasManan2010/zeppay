/** Encode VPA for NPCI USSD (*99*1*3#) — dots and @ become *. */
export function encodeVpaForUssd(vpa) {
  return vpa.replaceAll('.', '*').replaceAll('@', '*');
}

/** NPCI *99# send-to-UPI-ID with amount — opens Phone on iOS via tel: */
export function buildUssdTelLink({ vpa, amount }) {
  const rupees = Math.round(Number(amount) || 0);
  const encoded = encodeVpaForUssd(vpa);
  return `tel:*99*1*3*${encoded}*${rupees}%23`;
}

/** NPCI balance enquiry shortcut. */
export function buildBalanceTelLink() {
  return 'tel:*99*3%23';
}

/** Copy-friendly payment summary for the dialer session. */
export function buildPaymentSummary({ vpa, name, amount, note }) {
  const who = name?.trim() || vpa;
  let text = `Pay ₹${Number(amount).toFixed(2)} to ${who}\nUPI ID: ${vpa}`;
  if (note?.trim()) text += `\nNote: ${note.trim()}`;
  text += '\n\nDial *99# → Send to UPI ID → paste ID → enter amount → PIN in Phone.';
  return text;
}
