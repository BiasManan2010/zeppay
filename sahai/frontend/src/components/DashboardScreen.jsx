import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchDashboard } from '../lib/api'

const RISK_CLASS = {
  low: 'card-low',
  mid: 'card-mid',
  high: 'card-high',
}

export default function DashboardScreen() {
  const navigate = useNavigate()
  const [cases, setCases] = useState([])
  const [expanded, setExpanded] = useState(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchDashboard()
      .then((data) => setCases(data.cases || []))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [])

  return (
    <div className="screen dashboard-screen">
      <header className="screen-header">
        <h1>Supervisor dashboard</h1>
        <p className="subtitle">Cases sorted by risk</p>
      </header>

      {loading && <p className="hint">Loading cases…</p>}
      {error && <p className="error">{error}</p>}

      <div className="case-list">
        {cases.map((c) => (
          <article
            key={c.id}
            className={`case-card ${RISK_CLASS[c.risk_level] || ''}`}
            onClick={() => setExpanded(expanded === c.id ? null : c.id)}
          >
            <div className="case-header">
              <strong>{c.mother_name}</strong>
              <span className="risk-tag">{c.risk_level}</span>
            </div>
            <p className="case-meta">
              Escalation: {c.escalation_status} · {new Date(c.created_at).toLocaleString()}
            </p>
            {c.transcript && (
              <p className="snippet">{c.transcript.slice(0, 80)}…</p>
            )}
            {expanded === c.id && (
              <div className="case-detail">
                <p><strong>ID:</strong> {c.id}</p>
                {c.age && <p><strong>Age:</strong> {c.age}</p>}
                {c.confidence != null && (
                  <p><strong>Confidence:</strong> {(c.confidence * 100).toFixed(0)}%</p>
                )}
                {c.vitals && (
                  <pre>{JSON.stringify(c.vitals, null, 2)}</pre>
                )}
                {c.transcript && <p><strong>Transcript:</strong> {c.transcript}</p>}
              </div>
            )}
          </article>
        ))}
        {!loading && cases.length === 0 && (
          <p className="hint">No cases logged yet.</p>
        )}
      </div>

      <nav className="bottom-nav">
        <button type="button" onClick={() => navigate('/')}>New vitals</button>
      </nav>
    </div>
  )
}
