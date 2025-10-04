import React, { useState } from 'react'
import { XIcon } from './icons'
import ExerciseLogger from './ExerciseLogger'
import RestTimer from './RestTimer'

export default function ActiveWorkout({ session, exercises, onComplete, onCancel }) {
  const [currentExerciseIndex, setCurrentExerciseIndex] = useState(0)
  const [loggedData, setLoggedData] = useState({})
  const [showRestTimer, setShowRestTimer] = useState(false)
  const [startTime] = useState(Date.now())

  const currentExercise = session.items[currentExerciseIndex]
  const exerciseDetails = exercises.find(e => e.id === currentExercise?.exercise_id)
  const totalExercises = session.items.length
  const isLastExercise = currentExerciseIndex === totalExercises - 1

  const handleExerciseComplete = (exerciseId, sets) => {
    // Save logged data
    setLoggedData({
      ...loggedData,
      [exerciseId]: sets
    })

    if (isLastExercise) {
      // Finish workout
      finishWorkout({ ...loggedData, [exerciseId]: sets })
    } else {
      // Show rest timer and move to next exercise
      setShowRestTimer(true)
    }
  }

  const handleRestComplete = () => {
    setShowRestTimer(false)
    setCurrentExerciseIndex(currentExerciseIndex + 1)
  }

  const handleSkipRest = () => {
    setShowRestTimer(false)
    setCurrentExerciseIndex(currentExerciseIndex + 1)
  }

  const finishWorkout = (finalLoggedData) => {
    const durationMinutes = Math.round((Date.now() - startTime) / 60000)
    
    // Transform logged data to API format
    const logged_exercises = Object.entries(finalLoggedData).map(([exercise_id, sets]) => ({
      exercise_id,
      sets: sets.map(s => ({ reps: s.reps, weight: s.weight }))
    }))

    onComplete?.({ duration_minutes: durationMinutes, logged_exercises })
  }

  if (showRestTimer) {
    return (
      <RestTimer 
        duration={currentExercise.rest_seconds}
        onComplete={handleRestComplete}
        onSkip={handleSkipRest}
        nextExercise={exerciseDetails?.name}
      />
    )
  }

  return (
    <div className="active-workout">
      <div className="workout-progress">
        <div className="progress-header">
          <h2>Workout in Progress</h2>
          <button 
            className="cancel-button" 
            onClick={onCancel}
            type="button"
            aria-label="Cancel workout"
          >
            <span className="icon-left" aria-hidden><XIcon /></span> Cancel
          </button>
        </div>
        <div className="exercise-progress">
          <div className="progress-text" aria-live="polite">
            Exercise {currentExerciseIndex + 1} of {totalExercises}
          </div>
          <div className="progress-bar">
            <div 
              className="progress-fill" 
              style={{ width: `${((currentExerciseIndex) / totalExercises) * 100}%` }}
              role="progressbar"
              aria-valuenow={currentExerciseIndex}
              aria-valuemin={0}
              aria-valuemax={totalExercises}
            />
          </div>
        </div>
      </div>

      <ExerciseLogger
        exercise={currentExercise}
        exerciseDetails={exerciseDetails}
        onComplete={handleExerciseComplete}
        isLastExercise={isLastExercise}
      />
    </div>
  )
}
