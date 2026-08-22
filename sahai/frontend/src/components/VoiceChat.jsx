import { useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { uploadVoice, sendChat } from '../lib/api'
import { useCase } from '../context/CaseContext'

export default function VoiceChat() {
  const navigate = useNavigate()
  const { caseData, setChatReply } = useCase()
  const [recording, setRecording] = useState(false)
  const [messages, setMessages] = useState([])
  const [textInput, setTextInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [sessionId] = useState(() => crypto.randomUUID())
  const mediaRef = useRef(null)
  const chunksRef = useRef([])

  const riskLevel = caseData?.risk_level || 'low'
  const caseId = caseData?.case_id

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const recorder = new MediaRecorder(stream)
      chunksRef.current = []
      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data)
      }
      recorder.onstop = async () => {
        stream.getTracks().forEach((t) => t.stop())
        const blob = new Blob(chunksRef.current, { type: 'audio/webm' })
        await handleVoiceBlob(blob)
      }
      mediaRef.current = recorder
      recorder.start()
      setRecording(true)
    } catch {
      alert('Microphone access is required for voice input.')
    }
  }

  const stopRecording = () => {
    if (mediaRef.current?.state === 'recording') {
      mediaRef.current.stop()
      setRecording(false)
    }
  }

  const handleVoiceBlob = async (blob) => {
    setLoading(true)
    try {
      const { transcript } = await uploadVoice(blob)
      if (transcript) await sendMessage(transcript)
    } catch (err) {
      setMessages((m) => [...m, { role: 'error', content: err.message }])
    } finally {
      setLoading(false)
    }
  }

  const sendMessage = async (text) => {
    if (!text.trim()) return
    setMessages((m) => [...m, { role: 'user', content: text }])
    setLoading(true)
    try {
      const { reply } = await sendChat(text, sessionId, riskLevel, caseId)
      setMessages((m) => [...m, { role: 'assistant', content: reply }])
      setChatReply(reply)
    } catch (err) {
      setMessages((m) => [...m, { role: 'error', content: err.message }])
    } finally {
      setLoading(false)
      setTextInput('')
    }
  }

  return (
    <div className="screen voice-screen">
      <header className="screen-header">
        <h1>Voice &amp; chat</h1>
        <p className="subtitle">Describe symptoms — Hindi, Punjabi, or English</p>
      </header>

      <div className="chat-area">
        {messages.length === 0 && (
          <p className="hint">Tap the mic and describe what the mother reports.</p>
        )}
        {messages.map((msg, i) => (
          <div key={i} className={`bubble ${msg.role}`}>
            {msg.content}
          </div>
        ))}
        {loading && <p className="hint">Processing…</p>}
      </div>

      <div className="mic-row">
        <button
          type="button"
          className={`mic-btn ${recording ? 'recording' : ''}`}
          onClick={recording ? stopRecording : startRecording}
          aria-label="Record voice"
        >
          {recording ? '■' : '🎤'}
        </button>
      </div>

      <form
        className="text-chat"
        onSubmit={(e) => {
          e.preventDefault()
          sendMessage(textInput)
        }}
      >
        <input
          type="text"
          placeholder="Or type a message…"
          value={textInput}
          onChange={(e) => setTextInput(e.target.value)}
        />
        <button type="submit" disabled={loading}>Send</button>
      </form>

      <nav className="bottom-nav">
        <button type="button" onClick={() => navigate('/')}>Vitals</button>
        <button type="button" onClick={() => navigate('/result')}>Result</button>
        <button type="button" onClick={() => navigate('/dashboard')}>Dashboard</button>
      </nav>
    </div>
  )
}
