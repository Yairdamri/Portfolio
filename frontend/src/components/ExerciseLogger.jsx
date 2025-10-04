import React, { useState } from 'react'
import { CheckIcon, ArrowRightIcon } from './icons'

export default function ExerciseLogger({ exercise, exerciseDetails, onComplete, isLastExercise }) {
  const [loggedSets, setLoggedSets] = useState([])
  const [currentSet, setCurrentSet] = useState({
    reps: exercise.reps,
    weight: 0
  })

  const targetSets = exercise.sets
  const completedSets = loggedSets.length
  const isAllSetsComplete = completedSets >= targetSets

  const handleLogSet = () => {
    if (currentSet.reps <= 0) return
    
    setLoggedSets([...loggedSets, currentSet])
    setCurrentSet({ reps: exercise.reps, weight: currentSet.weight }) // Keep weight, reset reps
  }

  const handleComplete = () => {
    if (loggedSets.length === 0) return
    onComplete?.(exercise.exercise_id, loggedSets)
  }

  const handleSkip = () => {
    // Log with at least one set or skip entirely
    const sets = loggedSets.length > 0 ? loggedSets : [{ reps: 0, weight: 0 }]
    onComplete?.(exercise.exercise_id, sets)
  }

  return (
    <div className="exercise-logger">
      <div className="exercise-header">
        <h3 className="exercise-title">{exerciseDetails?.name || exercise.exercise_id}</h3>
        {exerciseDetails?.primary_muscle && (
          <span className="muscle-badge">{exerciseDetails.primary_muscle}</span>
        )}
      </div>

      <div className="target-info">
        <div className="target-item">
          <span className="target-label">Target:</span>
          <span className="target-value">{targetSets} sets × {exercise.reps} reps</span>
        </div>
        <div className="target-item">
          <span className="target-label">Rest:</span>
          <span className="target-value">{exercise.rest_seconds}s</span>
        </div>
      </div>

      {/* Logged Sets Table */}
      {loggedSets.length > 0 && (
        <div className="logged-sets">
          <h4 className="sets-title">Completed Sets</h4>
          <table className="sets-table" role="table" aria-label="Completed sets">
            <thead>
              <tr>
                <th>Set</th>
                <th>Reps</th>
                <th>Weight</th>
              </tr>
            </thead>
            <tbody>
              {loggedSets.map((set, idx) => (
                <tr key={idx}>
                  <td>{idx + 1}</td>
                  <td>{set.reps}</td>
                  <td>{set.weight > 0 ? `${set.weight} kg` : 'Bodyweight'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Current Set Input */}
      {!isAllSetsComplete && (
        <div className="current-set-input">
          <h4 className="input-title">Set {completedSets + 1} of {targetSets}</h4>
          <div className="input-grid">
            <div className="input-group">
              <label htmlFor="reps-input" className="input-label">Reps</label>
              <input
                id="reps-input"
                type="number"
                min="0"
                max="50"
                value={currentSet.reps}
                onChange={(e) => setCurrentSet({ ...currentSet, reps: Number(e.target.value) })}
                className="set-input"
                aria-label="Reps performed"
              />
            </div>
            <div className="input-group">
              <label htmlFor="weight-input" className="input-label">Weight (kg)</label>
              <input
                id="weight-input"
                type="number"
                min="0"
                step="0.5"
                value={currentSet.weight}
                onChange={(e) => setCurrentSet({ ...currentSet, weight: Number(e.target.value) })}
                className="set-input"
                aria-label="Weight used in kilograms"
              />
            </div>
          </div>
          <button
            className="log-set-button"
            onClick={handleLogSet}
            disabled={currentSet.reps <= 0}
            type="button"
          >
            <span className="icon-left" aria-hidden><CheckIcon /></span> Log Set {completedSets + 1}
          </button>
        </div>
      )}

      {/* Action Buttons */}
      <div className="exercise-actions">
        {isAllSetsComplete ? (
          <button
            className="complete-exercise-button"
            onClick={handleComplete}
            type="button"
          >
            {isLastExercise 
              ? (<><span className="icon-left" aria-hidden><CheckIcon /></span> Finish Workout</>) 
              : (<><span className="icon-left" aria-hidden><ArrowRightIcon /></span> Next Exercise</>)}
          </button>
        ) : (
          <button
            className="skip-button"
            onClick={handleSkip}
            disabled={loggedSets.length === 0}
            type="button"
          >
            Skip Exercise
          </button>
        )}
      </div>
    </div>
  )
}
