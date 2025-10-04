import React, { useState } from 'react'

const DAYS_OF_WEEK = [
  { id: 'monday', label: 'Mon', full: 'Monday' },
  { id: 'tuesday', label: 'Tue', full: 'Tuesday' },
  { id: 'wednesday', label: 'Wed', full: 'Wednesday' },
  { id: 'thursday', label: 'Thu', full: 'Thursday' },
  { id: 'friday', label: 'Fri', full: 'Friday' },
  { id: 'saturday', label: 'Sat', full: 'Saturday' },
  { id: 'sunday', label: 'Sun', full: 'Sunday' },
]

const DIFFICULTIES = [
  { id: 'beginner', label: 'Beginner', desc: 'New to working out' },
  { id: 'intermediate', label: 'Intermediate', desc: '6+ months experience' },
  { id: 'advanced', label: 'Advanced', desc: '2+ years experience' },
]

export default function WorkoutGenerator({ onGenerate, loading }) {
  const [selectedDays, setSelectedDays] = useState(['monday', 'wednesday', 'friday'])
  const [duration, setDuration] = useState(45)
  const [difficulty, setDifficulty] = useState('intermediate')
  const [weeks, setWeeks] = useState(4)
  const weekOptions = [1, 2, 4, 8, 12]

  const toggleDay = (dayId) => {
    if (selectedDays.includes(dayId)) {
      setSelectedDays(selectedDays.filter(d => d !== dayId))
    } else {
      setSelectedDays([...selectedDays, dayId])
    }
  }

  const handleGenerate = () => {
    if (selectedDays.length === 0) {
      alert('Please select at least one day')
      return
    }
    onGenerate?.({
      selected_days: selectedDays,
      duration_minutes: duration,
      difficulty,
      weeks,
    })
  }

  const onDifficultyKeyDown = (e) => {
    const idx = DIFFICULTIES.findIndex(d => d.id === difficulty)
    if (idx === -1) return
    let next = idx
    if (e.key === 'ArrowRight') next = (idx + 1) % DIFFICULTIES.length
    else if (e.key === 'ArrowLeft') next = (idx - 1 + DIFFICULTIES.length) % DIFFICULTIES.length
    else if (e.key === 'Home') next = 0
    else if (e.key === 'End') next = DIFFICULTIES.length - 1
    else return
    e.preventDefault()
    setDifficulty(DIFFICULTIES[next].id)
  }

  const onWeeksKeyDown = (e) => {
    const idx = weekOptions.findIndex(w => w === weeks)
    if (idx === -1) return
    let next = idx
    if (e.key === 'ArrowRight') next = (idx + 1) % weekOptions.length
    else if (e.key === 'ArrowLeft') next = (idx - 1 + weekOptions.length) % weekOptions.length
    else if (e.key === 'Home') next = 0
    else if (e.key === 'End') next = weekOptions.length - 1
    else return
    e.preventDefault()
    setWeeks(weekOptions[next])
  }

  return (
    <div className="generator-container">
      <div className="generator-section">
        <h3>Select Workout Days</h3>
        <div className="day-picker" role="group" aria-label="Select workout days of the week">
          {DAYS_OF_WEEK.map(day => (
            <button
              key={day.id}
              type="button"
              className={`day-button ${selectedDays.includes(day.id) ? 'selected' : ''}`}
              onClick={() => toggleDay(day.id)}
              aria-pressed={selectedDays.includes(day.id)}
              aria-label={day.full}
              title={day.full}
            >
              {day.label}
            </button>
          ))}
        </div>
        <div className="selected-summary" aria-live="polite">
          {selectedDays.length} day{selectedDays.length !== 1 ? 's' : ''} per week
        </div>
      </div>

      <div className="generator-section">
        <h3>Session Duration</h3>
        <div className="slider-container">
          <label htmlFor="duration-slider" className="sr-only">Session duration in minutes</label>
          <input
            type="range"
            min="15"
            max="120"
            step="5"
            value={duration}
            onChange={(e) => setDuration(Number(e.target.value))}
            className="duration-slider"
            id="duration-slider"
            aria-describedby="duration-display"
          />
          <div id="duration-display" className="duration-display" aria-live="polite">{duration} minutes</div>
        </div>
      </div>

      <div className="generator-section">
        <h3>Difficulty Level</h3>
        <div className="difficulty-picker" role="radiogroup" aria-label="Select difficulty">
          {DIFFICULTIES.map(diff => (
            <button
              key={diff.id}
              type="button"
              className={`difficulty-button ${difficulty === diff.id ? 'selected' : ''}`}
              onClick={() => setDifficulty(diff.id)}
              role="radio"
              aria-checked={difficulty === diff.id}
              tabIndex={difficulty === diff.id ? 0 : -1}
              onKeyDown={onDifficultyKeyDown}
            >
              <div className="diff-label">{diff.label}</div>
              <div className="diff-desc">{diff.desc}</div>
            </button>
          ))}
        </div>
      </div>

      <div className="generator-section">
        <h3>Program Duration</h3>
        <div className="weeks-picker" role="radiogroup" aria-label="Select program weeks">
          {weekOptions.map(w => (
            <button
              key={w}
              type="button"
              className={`week-button ${weeks === w ? 'selected' : ''}`}
              onClick={() => setWeeks(w)}
              role="radio"
              aria-checked={weeks === w}
              tabIndex={weeks === w ? 0 : -1}
              onKeyDown={onWeeksKeyDown}
            >
              {w} week{w > 1 ? 's' : ''}
            </button>
          ))}
        </div>
      </div>

      <button
        className="generate-button"
        onClick={handleGenerate}
        disabled={loading || selectedDays.length === 0}
      >
        {loading ? 'Generating...' : 'Generate My Workout'}
      </button>
    </div>
  )
}
