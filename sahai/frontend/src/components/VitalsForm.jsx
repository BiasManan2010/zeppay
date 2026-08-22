import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { submitVitals } from '../lib/api'
import { useCase } from '../context/CaseContext'

const FIELDS = [
  { key: 'mother_name', label: 'Mother name', type: 'text' },
  { key: 'age', label: 'Age', type: 'number', min: 10, max: 70 },
  { key: 'systolic_bp', label: 'Systolic BP', type: 'number', min: 70, max: 200 },
  { key: 'diastolic_bp', label: 'Diastolic BP', type: 'number', min: 40, max: 150 },
  { key: 'blood_sugar', label: 'Blood sugar (×10)', type: 'number', min: 6, max: 25, step: 0.1 },
  { key: 'body_temp', label: 'Body temp (°F)', type: 'number', min: 95, max: 105, step: 0.1 },
  { key: 'heart_rate', label: 'Heart rate', type: 'number', min: 40, max: 180 },
]

export default function VitalsForm() {
  const navigate = useNavigate()
  const { setCaseData } = useCase()
  const [form, setForm] = useState({
    mother_name: '',
    age: '',
    systolic_bp: '',
    diastolic_bp: '',
    blood_sugar: '',
    body_temp: '98',
    heart_rate: '',
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const onChange = (key, value) => setForm((f) => ({ ...f, [key]: value }))

  const onSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const payload = {
        mother_name: form.mother_name || 'Unknown',
        age: Number(form.age),
        systolic_bp: Number(form.systolic_bp),
        diastolic_bp: Number(form.diastolic_bp),
        blood_sugar: Number(form.blood_sugar),
        body_temp: Number(form.body_temp),
        heart_rate: Number(form.heart_rate),
      }
      const result = await submitVitals(payload)
      setCaseData({ ...result, mother_name: payload.mother_name, age: payload.age })
      navigate('/result')
    } catch (err) {
      setError(err.message || 'Failed to submit vitals')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="screen">
      <header className="screen-header">
        <h1>SahAI</h1>
        <p className="subtitle">Enter mother&apos;s vitals</p>
      </header>
      <form className="vitals-form" onSubmit={onSubmit}>
        {FIELDS.map((field) => (
          <label key={field.key} className="field">
            <span>{field.label}</span>
            <input
              type={field.type}
              min={field.min}
              max={field.max}
              step={field.step}
              required={field.key !== 'mother_name'}
              value={form[field.key]}
              onChange={(e) => onChange(field.key, e.target.value)}
            />
          </label>
        ))}
        {error && <p className="error">{error}</p>}
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Scoring…' : 'Check risk'}
        </button>
      </form>
      <nav className="bottom-nav">
        <button type="button" onClick={() => navigate('/voice')}>Voice symptoms</button>
        <button type="button" onClick={() => navigate('/dashboard')}>Dashboard</button>
      </nav>
    </div>
  )
}
