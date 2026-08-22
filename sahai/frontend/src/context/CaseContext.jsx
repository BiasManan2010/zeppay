import { createContext, useContext, useState } from 'react'

const CaseContext = createContext(null)

export function CaseProvider({ children }) {
  const [caseData, setCaseData] = useState(null)
  const [chatReply, setChatReply] = useState('')

  return (
    <CaseContext.Provider
      value={{ caseData, setCaseData, chatReply, setChatReply }}
    >
      {children}
    </CaseContext.Provider>
  )
}

export function useCase() {
  const ctx = useContext(CaseContext)
  if (!ctx) throw new Error('useCase must be used within CaseProvider')
  return ctx
}
