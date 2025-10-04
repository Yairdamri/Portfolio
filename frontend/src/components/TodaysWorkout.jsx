import React, { useState, useMemo } from 'react'
import { CalendarIcon, ChevronDownIcon, ChevronRightIcon, PlayIcon, CheckIcon } from './icons'

const DAYS_MAP = {
  'sunday': 0,
  'monday': 1,
  'tuesday': 2,
  'wednesday': 3,
  'thursday': 4,
  'friday': 5,
  'saturday': 6
}

export default function TodaysWorkout({ plan, exercises, onStartWorkout, completedSessions = [] }) {
  const [showUpcoming, setShowUpcoming] = useState(false)
  const [expanded, setExpanded] = useState({})
  
  const exById = useMemo(() => {
    const map = new Map()
    exercises.forEach(ex => map.set(ex.id, ex))
    return map
  }, [exercises])

  // Calculate today's workout and upcoming workouts
  const schedule = useMemo(() => {
    if (!plan) return { today: null, upcoming: [] }
    
    const now = new Date()
    const todayDayIndex = now.getDay() // 0=Sun, 1=Mon, etc.
    
    // Get selected days as day indices
    const selectedDayIndices = (plan.selected_days || []).map(day => DAYS_MAP[day.toLowerCase()])
    
    // Find today's workout
    let todayWorkout = null
    let nextWorkout = null
    
    if (selectedDayIndices.includes(todayDayIndex)) {
      // Today is a workout day - find which session
      const dayPosition = selectedDayIndices.indexOf(todayDayIndex)
      const currentWeek = Math.floor(completedSessions.length / plan.days_per_week)
      const sessionIndex = (currentWeek * plan.days_per_week) + dayPosition
      
      if (sessionIndex < plan.sessions.length && !completedSessions.includes(sessionIndex)) {
        todayWorkout = {
          session: plan.sessions[sessionIndex],
          sessionIndex,
          isToday: true,
          dayName: 'Today'
        }
      }
    }
    
    // Find next upcoming workouts (next 7 days)
    const upcoming = []
    for (let i = 1; i <= 7; i++) {
      const futureDate = new Date(now)
      futureDate.setDate(now.getDate() + i)
      const futureDayIndex = futureDate.getDay()
      
      if (selectedDayIndices.includes(futureDayIndex)) {
        const dayPosition = selectedDayIndices.indexOf(futureDayIndex)
        const weekOffset = Math.floor((completedSessions.length + upcoming.length + (todayWorkout ? 1 : 0)) / plan.days_per_week)
        const sessionIndex = (weekOffset * plan.days_per_week) + dayPosition
        
        if (sessionIndex < plan.sessions.length && !completedSessions.includes(sessionIndex)) {
          const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
          upcoming.push({
            session: plan.sessions[sessionIndex],
            sessionIndex,
            isToday: false,
            dayName: dayNames[futureDayIndex],
            date: futureDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
          })
        }
      }
    }

    // If no workout today, make first upcoming the "next" workout
    if (!todayWorkout && upcoming.length > 0) {
      nextWorkout = upcoming.shift()
      nextWorkout.isNext = true
    }
    
    return { today: todayWorkout || nextWorkout, upcoming }
  }, [plan, completedSessions])

  if (!schedule.today) {
    return (
      <div className="todays-workout-empty">
        <div className="empty-state-icon" aria-hidden>
          <CheckIcon />
        </div>
        <h3 className="empty-state-title">All Caught Up</h3>
        <p className="empty-state-message">
          You’ve completed all scheduled workouts.
        </p>
      </div>
    )
  }

  const { today, upcoming } = schedule
  const isCompleted = completedSessions.includes(today.sessionIndex)

  return (
    <div className="todays-workout-container">
      {/* Today's/Next Workout Card */}
      <div className="todays-workout-card">
        <div className="today-header">
          <div className="today-badge">
            <CalendarIcon className="badge-icon" /> {today.isToday ? 'Today' : today.isNext ? 'Next Up' : today.dayName}
          </div>
          {today.date && <span className="today-date">{today.date}</span>}
        </div>

        <h2 className="today-title">
          {today.isToday ? "Today's Workout" : "Next Workout"}
        </h2>

        <div className="today-exercises">
          {today.session.items.map((item, idx) => {
            const ex = exById.get(item.exercise_id)
            return (
              <div key={idx} className="today-exercise-item">
                <div className="exercise-number">{idx + 1}</div>
                <div className="exercise-info">
                  <div className="exercise-name">{ex?.name || item.exercise_id}</div>
                  <div className="exercise-details">
                    <span className="sets-reps">{item.sets} × {item.reps}</span>
                    {ex?.primary_muscle && (
                      <span className="muscle-tag-small">{ex.primary_muscle}</span>
                    )}
                  </div>
                </div>
              </div>
            )
          })}
        </div>

        {!isCompleted && (
          <button
            className="today-start-button"
            onClick={() => onStartWorkout(today.sessionIndex)}
            type="button"
            aria-label={`Start ${today.isToday ? "today's" : "next"} workout`}
          >
            <span className="icon-left" aria-hidden><PlayIcon /></span> Start Workout
          </button>
        )}

        {isCompleted && (
          <div className="today-completed-badge">
            <span className="icon-left" aria-hidden><CheckIcon /></span> <span>Completed</span>
          </div>
        )}
      </div>

      {/* Upcoming Workouts */}
      {upcoming.length > 0 && (
        <div className="upcoming-workouts">
          <button
            className="upcoming-toggle"
            onClick={() => setShowUpcoming(!showUpcoming)}
            type="button"
            aria-expanded={showUpcoming}
            aria-controls="upcoming-list"
          >
            <span>Upcoming Workouts ({upcoming.length})</span>
            <span className="toggle-icon" aria-hidden>
              {showUpcoming ? <ChevronDownIcon /> : <ChevronRightIcon />}
            </span>
          </button>

          {showUpcoming && (
            <div id="upcoming-list" className="upcoming-list">
              {upcoming.map((workout, idx) => {
                const isOpen = !!expanded[idx]
                const regionId = `upcoming-${idx}-panel`
                const headerId = `upcoming-${idx}-header`
                return (
                  <div key={idx} className="upcoming-item">
                    <div className="upcoming-day" id={headerId}>
                      <span className="day-name">{workout.dayName}</span>
                      <span className="day-date">{workout.date}</span>
                    </div>
                    <div className="upcoming-controls">
                      <div className="upcoming-preview">
                        {workout.session.items.length} exercises
                      </div>
                      <button
                        className="upcoming-expand"
                        type="button"
                        aria-expanded={isOpen}
                        aria-controls={regionId}
                        onClick={() => setExpanded({ ...expanded, [idx]: !isOpen })}
                      >
                        {isOpen ? 'Hide' : 'Details'}
                      </button>
                    </div>

                    {isOpen && (
                      <div
                        id={regionId}
                        className="upcoming-item-details"
                        role="region"
                        aria-labelledby={headerId}
                      >
                        <div className="upcoming-exercise-list">
                          {workout.session.items.map((item, i) => {
                            const ex = exById.get(item.exercise_id)
                            return (
                              <div key={i} className="upcoming-exercise-item">
                                <div className="exercise-name">{ex?.name || item.exercise_id}</div>
                                <div className="exercise-meta">
                                  <span className="sets-reps">{item.sets} × {item.reps}</span>
                                  {ex?.primary_muscle && (
                                    <span className="muscle-tag-small">{ex.primary_muscle}</span>
                                  )}
                                  <span className="rest">Rest: {item.rest_seconds}s</span>
                                </div>
                              </div>
                            )
                          })}
                        </div>
                        <button
                          className="upcoming-start-button"
                          type="button"
                          onClick={() => onStartWorkout(workout.sessionIndex)}
                          aria-label={`Start ${workout.dayName} workout`}
                        >
                          <span className="icon-left" aria-hidden><PlayIcon /></span> Start This Workout
                        </button>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
