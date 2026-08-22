import { useNavigate } from 'react-router-dom'
import { useCase } from '../context/CaseContext'

const BADGE_CLASS = {
  low: 'badge-low',
  mid: 'badge-mid',
  high: 'badge-high',
}

export default function ResultScreen() {
  const navigate = useNavigate()
  const { caseData, chatReply } = useCase()

  if (!caseData) {
    return (
      <div className="screen">
        <p>No vitals submitted yet.</p>
        <button className="btn-primary" onClick={() => navigate('/')}>
          Enter vitals
        </button>
      </div>
    )
  }

  const { risk_level, confidence, top_factors, escalation_status, mother_name } = caseData
  const badgeClass = BADGE_CLASS[risk_level] || 'badge-mid'

  return (
    <div className="screen result-screen">
      <header className="screen-header">
        <h1>Assessment</h1>
        <p className="subtitle">{mother_name}</p>
      </header>

      <div className={`risk-badge ${badgeClass}`}>
        {risk_level.toUpperCase()} RISK
      </div>
      <p className="confidence">Confidence: {(confidence * 100).toFixed(0)}%</p>

      {top_factors?.length > 0 && (
        <section className="card">
          <h2>Top contributing factors</h2>
          <ul>
            {top_factors.map((f) => (
              <li key={f.feature}>
                <strong>{f.feature.replace(/_/g, ' ')}</strong>
                <span>{f.impact > 0 ? '+' : ''}{f.impact.toFixed(3)}</span>
              </li>
            ))}
          </ul>
        </section>
      )}

      {chatReply && (
        <section className="card">
          <h2>Guidance</h2>
          <p>{chatReply}</p>
        </section>
      )}

      {risk_level === 'high' && (
        <div className="alert-box">
          Nurse has been notified
          {escalation_status && (
            <small> ({escalation_status})</small>
          )}
        </div>
      )}

      <nav className="bottom-nav">
        <button type="button" onClick={() => navigate('/voice')}>Add symptoms</button>
        <button type="button" onClick={() => navigate('/')}>New case</button>
        <button type="button" onClick={() => navigate('/dashboard')}>Dashboard</button>
      </nav>
    </div>
  )
}
