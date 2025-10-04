import React from 'react'

export function StatCardSkeleton() {
  return (
    <div className="stat-card skeleton">
      <div className="skeleton-circle" />
      <div className="skeleton-text large" />
      <div className="skeleton-text small" />
    </div>
  )
}

export function WorkoutCardSkeleton() {
  return (
    <div className="workout-card skeleton">
      <div className="workout-card-header">
        <div className="skeleton-text medium" />
        <div className="skeleton-text small" />
      </div>
      <div className="exercise-list">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="exercise-item">
            <div className="skeleton-text medium" />
            <div className="skeleton-text small" />
          </div>
        ))}
      </div>
    </div>
  )
}

export function WeeklyTrackerSkeleton() {
  return (
    <div className="weekly-tracker skeleton">
      <div className="skeleton-text large" style={{ margin: '0 auto 20px', width: '120px' }} />
      <div className="week-grid">
        {[1, 2, 3, 4, 5, 6, 7].map((i) => (
          <div key={i} className="week-day">
            <div className="skeleton-text small" />
            <div className="skeleton-circle small" />
          </div>
        ))}
      </div>
      <div className="skeleton-text medium" style={{ margin: '12px auto 0' }} />
    </div>
  )
}
