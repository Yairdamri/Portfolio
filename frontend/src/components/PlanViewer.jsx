import React, { useMemo } from 'react'

export default function PlanViewer({ plan, exercises }) {
  const exById = useMemo(() => {
    const m = new Map()
    for (const ex of exercises || []) m.set(ex.id, ex)
    return m
  }, [exercises])

  const totalSessions = plan.sessions?.length ?? 0

  return (
    <div className="plan-viewer">
      <div className="plan-summary">
        <div className="badges">
          <span className="badge">{plan.weeks} week{plan.weeks > 1 ? 's' : ''}</span>
          <span className="badge">{plan.days_per_week} days/week</span>
          <span className="badge">{totalSessions} sessions</span>
        </div>
        <div className="row">
          <input className="mono" readOnly value={plan.id} />
          <button onClick={() => navigator.clipboard?.writeText(plan.id)}>Copy ID</button>
        </div>
      </div>

      <div className="session-grid">
        {(plan.sessions ?? []).map((s, idx) => {
          const week = Math.floor(idx / plan.days_per_week) + 1
          const day = s.day_index
          return (
            <div key={idx} className="session-card">
              <div className="session-head">
                <div className="session-title">Week {week} • Day {day}</div>
              </div>
              <div className="session-items">
                {(s.items ?? []).map((it, j) => {
                  const ex = exById.get(it.exercise_id)
                  const title = ex?.name || it.exercise_id
                  const sub = ex?.primary_muscle || '—'
                  return (
                    <div key={j} className="session-item">
                      <div className="session-item-title">{title}</div>
                      <div className="session-item-sub">{sub} • {it.sets}x{it.reps}</div>
                    </div>
                  )
                })}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
