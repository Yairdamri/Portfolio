import React, { useEffect, useMemo, useState } from 'react'
import { CalendarIcon, DumbbellIcon, ClipboardIcon, RefreshIcon, SaveIcon, TrashIcon } from './icons'

function buildQuery(params) {
  const sp = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '' && !(typeof v === 'number' && Number.isNaN(v))) {
      sp.append(k, String(v))
    }
  })
  return sp.toString()
}

export default function History({ exercises = [] }) {
  const [filters, setFilters] = useState({
    date_from: '',
    date_to: '',
    muscle: '',
    difficulty: '',
    limit: 100,
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [data, setData] = useState({ items: [], count: 0 })

  const muscles = useMemo(() => {
    const set = new Set()
    exercises.forEach(ex => ex.primary_muscle && set.add(ex.primary_muscle))
    return Array.from(set).sort()
  }, [exercises])

  const fetchHistory = async () => {
    setLoading(true)
    setError(null)
    try {
      const qs = buildQuery(filters)
      const token = localStorage.getItem('token')
      const res = await fetch(`/v1/workouts/history?${qs}`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      })
      const text = await res.text()
      const json = text ? JSON.parse(text) : { items: [], count: 0 }
      if (!res.ok) {
        if (res.status === 401) {
          window.location.hash = '#/login'
        }
        throw new Error(json?.detail || res.statusText)
      }
      setData(json)
    } catch (e) {
      setError(e.message)
      setData({ items: [], count: 0 })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    // initial load
    fetchHistory()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const onExportCSV = () => {
    const headers = [
      'completed_at',
      'plan_id',
      'session_index',
      'duration_minutes',
      'muscles',
      'total_sets',
      'total_reps',
      'total_volume',
      'difficulty',
    ]
    const rows = data.items.map(it => [
      it.completion.completed_at,
      it.completion.plan_id,
      it.completion.session_index,
      it.completion.duration_minutes,
      (it.muscles || []).join('|'),
      it.total_sets,
      it.total_reps,
      it.total_volume,
      it.difficulty || '',
    ])
    const csv = [headers.join(','), ...rows.map(r => r.map(v => String(v).replaceAll('"', '""')).join(','))].join('\n')
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `workout_history_${new Date().toISOString().slice(0,10)}.csv`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  const deleteWorkout = async (completionId) => {
    const confirmed = window.confirm('Are you sure you want to delete this workout entry?')
    if (!confirmed) return

    try {
      const token = localStorage.getItem('token')
      const res = await fetch(`/v1/workouts/${completionId}`, {
        method: 'DELETE',
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      })

      if (!res.ok) {
        if (res.status === 401) {
          window.location.hash = '#/login'
          return
        }
        throw new Error(`Failed to delete workout: ${res.status}`)
      }

      // Remove the deleted item from the UI
      setData(prev => ({
        items: prev.items.filter(it => it.completion.id !== completionId),
        count: prev.count - 1,
      }))
    } catch (e) {
      alert(`Error deleting workout: ${e.message}`)
    }
  }

  return (
    <section className="card">
      <h2>Workout History</h2>

      <div className="form-grid" style={{ marginBottom: 12 }}>
        <div>
          <label htmlFor="date_from" className="input-label">From</label>
          <input id="date_from" type="date" value={filters.date_from}
            onChange={e => setFilters({ ...filters, date_from: e.target.value })}
          />
        </div>
        <div>
          <label htmlFor="date_to" className="input-label">To</label>
          <input id="date_to" type="date" value={filters.date_to}
            onChange={e => setFilters({ ...filters, date_to: e.target.value })}
          />
        </div>
        <div>
          <label htmlFor="muscle" className="input-label">Muscle</label>
          <select id="muscle" value={filters.muscle}
            onChange={e => setFilters({ ...filters, muscle: e.target.value })}
            className="set-input"
          >
            <option value="">All</option>
            {muscles.map(m => <option key={m} value={m}>{m}</option>)}
          </select>
        </div>
        <div>
          <label htmlFor="difficulty" className="input-label">Difficulty</label>
          <select id="difficulty" value={filters.difficulty}
            onChange={e => setFilters({ ...filters, difficulty: e.target.value })}
            className="set-input"
          >
            <option value="">All</option>
            <option value="beginner">Beginner</option>
            <option value="intermediate">Intermediate</option>
            <option value="advanced">Advanced</option>
          </select>
        </div>
        <div>
          <label htmlFor="limit" className="input-label">Limit</label>
          <input id="limit" type="number" min="1" max="500" value={filters.limit}
            onChange={e => setFilters({ ...filters, limit: Number(e.target.value) || 100 })}
          />
        </div>
        <div className="row" style={{ alignItems: 'flex-end' }}>
          <button onClick={fetchHistory} disabled={loading} className="action-button primary" type="button">
            <span className="icon-left" aria-hidden><RefreshIcon /></span> {loading ? 'Loading…' : 'Apply Filters'}
          </button>
          <button onClick={onExportCSV} disabled={data.count === 0} className="action-button secondary" type="button">
            <span className="icon-left" aria-hidden><SaveIcon /></span> Export CSV
          </button>
        </div>
      </div>

      {error && (
        <div className="error-message" role="alert">Error: {error}</div>
      )}

      <div className="table-wrapper">
        <table className="table" role="table" aria-label="Workout history">
          <thead>
            <tr>
              <th>Date</th>
              <th>Plan</th>
              <th>Session</th>
              <th>Duration</th>
              <th>Muscles</th>
              <th>Sets</th>
              <th>Reps</th>
              <th>Volume</th>
              <th>Difficulty</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {data.items.map((it) => (
              <tr key={it.completion.id}>
                <td>{new Date(it.completion.completed_at).toLocaleString()}</td>
                <td className="mono">{it.completion.plan_id.slice(0,8)}…</td>
                <td>{it.completion.session_index + 1}</td>
                <td>{it.completion.duration_minutes} min</td>
                <td>{(it.muscles || []).join(', ')}</td>
                <td>{it.total_sets}</td>
                <td>{it.total_reps}</td>
                <td>{it.total_volume}</td>
                <td>{it.difficulty || '-'}</td>
                <td>
                  <button 
                    onClick={() => deleteWorkout(it.completion.id)}
                    className="action-button secondary"
                    style={{ padding: '4px 8px', fontSize: '0.85rem' }}
                    title="Delete this workout"
                    type="button"
                  >
                    <TrashIcon />
                  </button>
                </td>
              </tr>
            ))}
            {data.count === 0 && !loading && (
              <tr>
                <td colSpan={10} style={{ textAlign: 'center', color: 'var(--text-dark)' }}>No results</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  )
}
