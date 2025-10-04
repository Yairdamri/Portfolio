import React, { useEffect, useRef } from 'react'

export default function Tabs({ tabs, active, onChange, idBase = 'tabs' }) {
  const refs = useRef([])

  useEffect(() => {
    // Keep refs array length in sync
    refs.current = refs.current.slice(0, tabs.length)
  }, [tabs.length])

  const onKeyDown = (e) => {
    const idx = tabs.findIndex(t => t.id === active)
    if (idx === -1) return
    let next = idx
    if (e.key === 'ArrowRight') next = (idx + 1) % tabs.length
    else if (e.key === 'ArrowLeft') next = (idx - 1 + tabs.length) % tabs.length
    else if (e.key === 'Home') next = 0
    else if (e.key === 'End') next = tabs.length - 1
    else return
    e.preventDefault()
    const id = tabs[next].id
    onChange?.(id)
    refs.current[next]?.focus()
  }

  return (
    <nav className="tabs" role="tablist" aria-label="Primary" aria-orientation="horizontal">
      {tabs.map((t, i) => {
        const isActive = active === t.id
        const tabId = `${idBase}-tab-${t.id}`
        const panelId = `${idBase}-panel-${t.id}`
        return (
          <button
            key={t.id}
            ref={el => refs.current[i] = el}
            id={tabId}
            role="tab"
            aria-selected={isActive}
            aria-controls={panelId}
            tabIndex={isActive ? 0 : -1}
            className={`tab ${isActive ? 'active' : ''}`}
            onClick={() => onChange?.(t.id)}
            onKeyDown={onKeyDown}
            type="button"
          >
            {t.icon ? <span className="tab-icon" aria-hidden>{t.icon}</span> : null}
            <span>{t.label}</span>
          </button>
        )
      })}
    </nav>
  )
}
