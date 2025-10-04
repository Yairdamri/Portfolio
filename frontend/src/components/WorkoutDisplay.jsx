import React, { useState } from 'react'
import ActiveWorkout from './ActiveWorkout'
import { CalendarIcon, DumbbellIcon, ClipboardIcon, CheckIcon, PlayIcon, SaveIcon, RefreshIcon } from './icons'

export default function WorkoutDisplay({ plan, exercises, onComplete, completedSessions = [] }) {
  const [activeSession, setActiveSession] = useState(null)
  if (!plan) return null

  const exById = new Map()
  for (const ex of exercises || []) exById.set(ex.id, ex)

  const sessionsPerWeek = plan.days_per_week
  const weeks = []
  
  // Group sessions by week
  for (let w = 0; w < plan.weeks; w++) {
    const weekSessions = plan.sessions.slice(w * sessionsPerWeek, (w + 1) * sessionsPerWeek)
    weeks.push({ week: w + 1, sessions: weekSessions, startIndex: w * sessionsPerWeek })
  }

  const isSessionCompleted = (sessionIndex) => {
    return completedSessions.includes(sessionIndex)
  }

  const handleStartWorkout = (sessionIndex) => {
    setActiveSession(sessionIndex)
  }

  const handleWorkoutComplete = (sessionIndex, data) => {
    setActiveSession(null)
    onComplete?.(sessionIndex, data)
  }

  const handleCancelWorkout = () => {
    setActiveSession(null)
  }

  // If a workout is active, show ActiveWorkout view
  if (activeSession !== null) {
    const session = plan.sessions[activeSession]
    return (
      <ActiveWorkout
        session={session}
        exercises={exercises}
        onComplete={(data) => handleWorkoutComplete(activeSession, data)}
        onCancel={handleCancelWorkout}
      />
    )
  }

  return (
    <div className="workout-display">
      <div className="workout-header">
        <h2>Your Workout Plan</h2>
        <div className="plan-meta">
          <span className="meta-item"><span className="icon-left" aria-hidden><CalendarIcon /></span> {plan.weeks} week{plan.weeks > 1 ? 's' : ''}</span>
          <span className="meta-item"><span className="icon-left" aria-hidden><DumbbellIcon /></span> {plan.days_per_week} days/week</span>
          <span className="meta-item"><span className="icon-left" aria-hidden><ClipboardIcon /></span> {plan.sessions.length} sessions</span>
        </div>
      </div>

      {weeks.map(({ week, sessions, startIndex }) => (
        <div key={week} className="week-section">
          <h3 className="week-title">Week {week}</h3>
          <div className="workout-grid">
            {sessions.map((session, idx) => {
              const sessionIndex = startIndex + idx
              const isCompleted = isSessionCompleted(sessionIndex)
              return (
              <div key={idx} className={`workout-card ${isCompleted ? 'completed' : ''}`}>
                <div className="workout-card-header">
                  <span className="day-label">Day {session.day_index}</span>
                  <span className="exercise-count">{session.items.length} exercises</span>
                  {isCompleted && <span className="completion-badge"><span className="icon-left" aria-hidden><CheckIcon /></span>Done</span>}
                </div>
                <div className="exercise-list">
                  {session.items.map((item, i) => {
                    const ex = exById.get(item.exercise_id)
                    return (
                      <div key={i} className="exercise-item">
                        <div className="exercise-name">
                          {ex?.name || item.exercise_id}
                        </div>
                        <div className="exercise-details">
                          <span className="sets-reps">{item.sets} × {item.reps}</span>
                          <span className="rest">Rest: {item.rest_seconds}s</span>
                        </div>
                        {ex?.primary_muscle && (
                          <div className="muscle-tag">{ex.primary_muscle}</div>
                        )}
                      </div>
                    )
                  })}
                </div>
                {!isCompleted && (
                  <div className="session-actions">
                    <button 
                      className="start-workout-button"
                      type="button"
                      aria-label={`Start workout ${sessionIndex + 1}`}
                      onClick={() => handleStartWorkout(sessionIndex)}
                    >
                      <span className="icon-left" aria-hidden><PlayIcon /></span> Start Workout
                    </button>
                    {onComplete && (
                      <button 
                        className="mark-done-button secondary"
                        type="button"
                        aria-label={`Mark session ${sessionIndex + 1} as done`}
                        onClick={() => onComplete(sessionIndex, { duration_minutes: 45, logged_exercises: [] })}
                      >
                        <span className="icon-left" aria-hidden><CheckIcon /></span> Mark as Done
                      </button>
                    )}
                  </div>
                )}
              </div>
              )
            })}
          </div>
        </div>
      ))}

      <div className="workout-actions">
        <button className="action-button primary" type="button" aria-label="Save plan">
          <span className="icon-left" aria-hidden><SaveIcon /></span> Save Plan
        </button>
        <button className="action-button secondary" type="button" aria-label="Generate new plan">
          <span className="icon-left" aria-hidden><RefreshIcon /></span> Generate New
        </button>
      </div>
    </div>
  )
}
