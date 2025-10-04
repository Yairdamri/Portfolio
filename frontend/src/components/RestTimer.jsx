import React, { useState, useEffect } from 'react'
import { ArrowRightIcon } from './icons'

export default function RestTimer({ duration, onComplete, onSkip, nextExercise }) {
  const [timeLeft, setTimeLeft] = useState(duration)

  useEffect(() => {
    if (timeLeft <= 0) {
      onComplete?.()
      return
    }

    const timer = setInterval(() => {
      setTimeLeft(t => t - 1)
    }, 1000)

    return () => clearInterval(timer)
  }, [timeLeft, onComplete])

  const progress = ((duration - timeLeft) / duration) * 100
  const minutes = Math.floor(timeLeft / 60)
  const seconds = timeLeft % 60

  return (
    <div className="rest-timer">
      <div className="timer-content">
        <h2 className="timer-title">Rest Period</h2>
        <p className="next-exercise-preview">Next: {nextExercise || 'Exercise'}</p>
        
        <div className="timer-circle">
          <svg className="timer-svg" viewBox="0 0 200 200" aria-hidden="true">
            <circle
              className="timer-bg"
              cx="100"
              cy="100"
              r="90"
            />
            <circle
              className="timer-progress"
              cx="100"
              cy="100"
              r="90"
              style={{
                strokeDasharray: `${2 * Math.PI * 90}`,
                strokeDashoffset: `${2 * Math.PI * 90 * (1 - progress / 100)}`
              }}
            />
          </svg>
          <div className="timer-display" aria-live="polite" aria-atomic="true">
            <span className="timer-time">
              {minutes > 0 ? `${minutes}:${seconds.toString().padStart(2, '0')}` : seconds}
            </span>
            <span className="timer-label">seconds</span>
          </div>
        </div>

        <button
          className="skip-rest-button"
          onClick={onSkip}
          type="button"
          aria-label="Skip rest period"
        >
          <span className="icon-left" aria-hidden><ArrowRightIcon /></span> Skip Rest
        </button>
      </div>
    </div>
  )
}
