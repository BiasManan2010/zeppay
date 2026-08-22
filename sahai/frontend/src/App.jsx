import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { CaseProvider } from './context/CaseContext'
import VitalsForm from './components/VitalsForm'
import VoiceChat from './components/VoiceChat'
import ResultScreen from './components/ResultScreen'
import DashboardScreen from './components/DashboardScreen'
import './App.css'

export default function App() {
  return (
    <CaseProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<VitalsForm />} />
          <Route path="/voice" element={<VoiceChat />} />
          <Route path="/result" element={<ResultScreen />} />
          <Route path="/dashboard" element={<DashboardScreen />} />
        </Routes>
      </BrowserRouter>
    </CaseProvider>
  )
}
