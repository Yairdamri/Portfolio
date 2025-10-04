import React from 'react'
import { CheckIcon, CircleIcon } from './icons'

const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

export default function WeeklyTracker({ summary, plannedWorkoutsPerWeek = null }) {
  const completedDays = new Set()
  
  // Map completions to days of week
  if (summary?.this_week_completions) {
    summary.this_week_completions.forEach(c => {
      const date = new Date(c.completed_at)
      const dayIndex = (date.getDay() + 6) % 7 // Convert Sun=0 to Mon=0
      completedDays.add(dayIndex)
    })
  }

  // Use planned workouts if available, otherwise fall back to 7 days
  const targetWorkouts = plannedWorkoutsPerWeek || 7
  const completedCount = summary?.workouts_completed || 0
  const completionRate = targetWorkouts > 0 ? 
    (completedCount / targetWorkouts * 100).toFixed(0) : 0

  return (
    <div className="weekly-tracker" aria-labelledby="weekly-title">
      <h3 id="weekly-title">This Week</h3>
      <div className="week-grid" role="grid" aria-label="This week's workout completion">
        {DAYS.map((day, idx) => {
          const completed = completedDays.has(idx)
          return (
            <div 
              key={idx} 
              className={`week-day ${completed ? 'completed' : ''}`}
              role="gridcell"
              aria-label={`${day} ${completed ? 'completed' : 'not completed'}`}
            >
              <div className="day-name">{day}</div>
              <div className="day-indicator" aria-hidden>
                {completed ? <CheckIcon /> : <CircleIcon />}
              </div>
            </div>
          )
        })}
      </div>
      <div className="progress-bar" aria-hidden>
        <div 
          className="progress-fill" 
          style={{ width: `${completionRate}%` }}
        />
      </div>
      <div className="progress-text" aria-live="polite">
        {completedCount} / {targetWorkouts} workouts this week
      </div>
    </div>
  )
}
