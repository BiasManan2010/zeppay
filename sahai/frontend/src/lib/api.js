const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'

export async function submitVitals(data) {
  const res = await fetch(`${API_BASE}/api/vitals`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  })
  if (!res.ok) throw new Error(await res.text())
  return res.json()
}

export async function uploadVoice(blob) {
  const form = new FormData()
  form.append('audio', blob, 'recording.webm')
  const res = await fetch(`${API_BASE}/api/voice`, {
    method: 'POST',
    body: form,
  })
  if (!res.ok) throw new Error(await res.text())
  return res.json()
}

export async function sendChat(message, sessionId, riskLevel, caseId) {
  const res = await fetch(`${API_BASE}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message,
      session_id: sessionId,
      risk_level: riskLevel,
      case_id: caseId,
    }),
  })
  if (!res.ok) throw new Error(await res.text())
  return res.json()
}

export async function escalateCase(payload) {
  const res = await fetch(`${API_BASE}/api/escalate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  })
  if (!res.ok) throw new Error(await res.text())
  return res.json()
}

export async function fetchDashboard() {
  const res = await fetch(`${API_BASE}/api/dashboard`)
  if (!res.ok) throw new Error(await res.text())
  return res.json()
}
