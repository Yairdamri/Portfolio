import React, { useEffect, useMemo, useState } from 'react'
import Header from './components/Header'
import PlanViewer from './components/PlanViewer'
import WorkoutGenerator from './components/WorkoutGenerator'
import WorkoutDisplay from './components/WorkoutDisplay'
import TodaysWorkout from './components/TodaysWorkout'
import ActiveWorkout from './components/ActiveWorkout'
import WeeklyTracker from './components/WeeklyTracker'
import History from './components/History'
import { StatCardSkeleton, WeeklyTrackerSkeleton } from './components/LoadingSkeleton'
import { CalendarIcon, DumbbellIcon, ClipboardIcon, CheckCircleIcon, TimerIcon, ChartBarIcon, ArrowRightIcon } from './components/icons'
import Login from './components/Login'
import Register from './components/Register'

function useJsonFetcher() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [data, setData] = useState(null)

  const run = async (path, options) => {
    setLoading(true)
    setError(null)
    try {
      const token = localStorage.getItem('token')
      const headers = {
        'Content-Type': 'application/json',
        ...(options?.headers || {}),
        ...(token && !(options?.headers || {})['Authorization'] ? { Authorization: `Bearer ${token}` } : {}),
      }
      const res = await fetch(path, { ...(options || {}), headers })
      const text = await res.text()
      const json = text ? JSON.parse(text) : null
      if (!res.ok) {
        if (res.status === 401) {
          window.location.hash = '#/login'
        }
        throw new Error(json?.error?.message || json?.detail || res.statusText)
      }
      setData(json)
      return json
    } catch (e) {
      setError(e.message)
      setData(null)
      throw e
    } finally {
      setLoading(false)
    }
  }

  return { loading, error, data, run }
}

export default function App() {
  // API hooks
  const health = useJsonFetcher()
  const dbping = useJsonFetcher()
  const exercises = useJsonFetcher()
  const createPlan = useJsonFetcher()
  const getPlan = useJsonFetcher()
  const listPlansFx = useJsonFetcher()
  const generateWorkout = useJsonFetcher()
  const weeklySummary = useJsonFetcher()
  const completeWorkout = useJsonFetcher()

  // UI state
  const getRouteFromHash = () => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null
    const hash = window.location.hash || (token ? '#/generator' : '#/login')
    const route = hash.replace('#/', '')
    if (['generator', 'workouts', 'dashboard', 'exercises', 'history', 'login', 'register'].includes(route)) return route
    return 'generator'
  }
  const [route, setRoute] = useState(getRouteFromHash()) // generator | workouts | dashboard | exercises
  const [user, setUser] = useState(null)
  const [authReady, setAuthReady] = useState(false)
  const [days, setDays] = useState(3)
  const [weeks, setWeeks] = useState(1)
  const [planId, setPlanId] = useState('')
  const [generatedPlan, setGeneratedPlan] = useState(null)
  const [completedSessions, setCompletedSessions] = useState([])
  const [activeSessionIndex, setActiveSessionIndex] = useState(null)

  // Derived
  const plans = useMemo(() => listPlansFx.data?.items ?? [], [listPlansFx.data])

  // Handle hash routing
  useEffect(() => {
    const onHashChange = () => setRoute(getRouteFromHash())
    window.addEventListener('hashchange', onHashChange)
    return () => window.removeEventListener('hashchange', onHashChange)
  }, [])

  // Bootstrap auth
  useEffect(() => {
    const token = localStorage.getItem('token')
    if (token && !user) {
      fetch('/v1/auth/me', { headers: { Authorization: `Bearer ${token}` } })
        .then(r => r.ok ? r.json() : null)
        .then(u => { if (u) setUser(u) })
        .catch(() => {})
        .finally(() => setAuthReady(true))
    } else {
      setAuthReady(true)
    }
  }, [])

  // Route guard: redirect to login if unauthenticated on protected routes
  useEffect(() => {
    const protectedRoutes = ['generator', 'workouts', 'dashboard', 'exercises', 'history']
    const token = localStorage.getItem('token')
    if (authReady && protectedRoutes.includes(route) && (!token || !user)) {
      if (window.location.hash !== '#/login') {
        window.location.hash = '#/login'
      }
    }
  }, [authReady, route, user])

  // If authenticated, avoid showing login/register pages
  useEffect(() => {
    if (!authReady) return
    if (user && (route === 'login' || route === 'register')) {
      window.location.hash = '#/generator'
    }
  }, [authReady, route, user])

  // Fetch baseline data for dashboard
  useEffect(() => {
    if (route === 'dashboard' && user) {
      if (!health.data && !health.loading) health.run('/health')
      if (!dbping.data && !dbping.loading) dbping.run('/v1/db/ping')
      if (!exercises.data && !exercises.loading) exercises.run('/v1/exercises')
      if (!listPlansFx.data && !listPlansFx.loading) listPlansFx.run('/v1/plans')
      // Fetch weekly summary for stats
      weeklySummary.run('/v1/workouts/summary')
    }
  }, [route, user])

  useEffect(() => {
    if ((route === 'exercises' || route === 'history') && user && !exercises.data && !exercises.loading) {
      exercises.run('/v1/exercises')
    }
  }, [route, user])

  useEffect(() => {
    if (route === 'plans') {
      listPlansFx.run('/v1/plans')
      if (!exercises.data && !exercises.loading) {
        exercises.run('/v1/exercises')
      }
    }
  }, [route])

  const onCreate = async () => {
    const body = { days_per_week: Number(days), weeks: Number(weeks) }
    const res = await createPlan.run('/v1/plans', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
    if (res?.id) {
      setPlanId(res.id)
      // refresh list and select
      listPlansFx.run('/v1/plans')
      getPlan.run(`/v1/plans/${encodeURIComponent(res.id)}`)
    }
  }

  const onGenerateWorkout = async (params) => {
    if (!exercises.data) {
      await exercises.run('/v1/exercises')
    }
    const res = await generateWorkout.run('/v1/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(params),
    })
    if (res) {
      setGeneratedPlan(res)
      setCompletedSessions([]) // Reset completions for new plan
      // Optionally refresh plans list
      listPlansFx.run('/v1/plans')
    }
  }

  const onCompleteSession = async (sessionIndex, data = {}) => {
    if (!generatedPlan) return
    
    const res = await completeWorkout.run('/v1/workouts/complete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        plan_id: generatedPlan.id,
        session_index: sessionIndex,
        duration_minutes: data.duration_minutes || 45,
        logged_exercises: data.logged_exercises || [],
      }),
    })
    
    if (res) {
      setCompletedSessions([...completedSessions, sessionIndex])
      // Refresh weekly summary
      weeklySummary.run('/v1/workouts/summary')
    }
  }

  const onSelectPlan = (id) => {
    setPlanId(id)
    getPlan.run(`/v1/plans/${encodeURIComponent(id)}`)
  }

  const tabs = [
    { id: 'generator', label: 'Generator', icon: '✨' },
    { id: 'dashboard', label: 'Dashboard', icon: '🏠' },
    { id: 'exercises', label: 'Exercises', icon: '🏋️' },
  ]

  return (
    <div>
      <Header active={route} user={user} onSignOut={() => { localStorage.removeItem('token'); setUser(null); window.location.hash = '#/login' }} />

      <main id="main">
        {route === 'generator' && (
          <section className="card">
            <WorkoutGenerator 
              onGenerate={onGenerateWorkout} 
              loading={generateWorkout.loading}
            />
            {generateWorkout.error && (
              <div className="error-message" role="alert">
                Error: {generateWorkout.error}
              </div>
            )}
            {!generatedPlan && !generateWorkout.loading && !generateWorkout.error && (
              <div className="empty-state">
                <div className="empty-state-icon" aria-hidden><DumbbellIcon /></div>
                <h2 className="empty-state-title">Ready to Start?</h2>
                <p className="empty-state-message">
                  Select your workout days, duration, and difficulty level above, 
                  then click "Generate My Workout" to create your personalized plan.
                </p>
              </div>
            )}
            {generatedPlan && (
              <div className="empty-state-action">
                <button className="action-button primary" type="button" onClick={() => { window.location.hash = '#/workouts' }}>
                  <span className="icon-left" aria-hidden><ArrowRightIcon /></span> Go to Workouts
                </button>
              </div>
            )}
          </section>
        )}

        {route === 'login' && (
          <Login onSuccess={(auth) => { localStorage.setItem('token', auth.token); setUser({ id: auth.user_id, email: auth.email, name: auth.name }); window.location.hash = '#/generator' }} />
        )}

        {route === 'register' && (
          <Register onSuccess={(auth) => { localStorage.setItem('token', auth.token); setUser({ id: auth.user_id, email: auth.email, name: auth.name }); window.location.hash = '#/generator' }} />
        )}

        {route === 'workouts' && (
          <section className="card">
            {!generatedPlan ? (
              <div className="empty-state">
                <div className="empty-state-icon" aria-hidden><CalendarIcon /></div>
                <h2 className="empty-state-title">No Plan Yet</h2>
                <p className="empty-state-message">Create your plan in the Generator, then come back to start your workouts.</p>
                <div className="empty-state-action">
                  <button className="action-button primary" type="button" onClick={() => { window.location.hash = '#/generator' }}>
                    Open Generator
                  </button>
                </div>
              </div>
            ) : (
              activeSessionIndex !== null ? (
                <ActiveWorkout
                  session={generatedPlan.sessions[activeSessionIndex]}
                  exercises={exercises.data?.items ?? []}
                  onComplete={(data) => {
                    onCompleteSession(activeSessionIndex, data)
                    setActiveSessionIndex(null)
                  }}
                  onCancel={() => setActiveSessionIndex(null)}
                />
              ) : (
                <TodaysWorkout
                  plan={generatedPlan}
                  exercises={exercises.data?.items ?? []}
                  onStartWorkout={(sessionIndex) => setActiveSessionIndex(sessionIndex)}
                  completedSessions={completedSessions}
                />
              )
            )}
          </section>
        )}

        {route === 'dashboard' && (
          <>
            <section className="stats-grid">
              {weeklySummary.loading ? (
                <>
                  <StatCardSkeleton />
                  <StatCardSkeleton />
                  <StatCardSkeleton />
                  <StatCardSkeleton />
                </>
              ) : (
                <>
                  <div className="stat-card">
                    <div className="stat-icon" aria-hidden><CalendarIcon /></div>
                    <div className="stat-value">{weeklySummary.data?.current_streak ?? 0}</div>
                    <div className="stat-label">Day Streak</div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon" aria-hidden><CheckCircleIcon /></div>
                    <div className="stat-value">{weeklySummary.data?.workouts_completed ?? 0}</div>
                    <div className="stat-label">This Week</div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon" aria-hidden><TimerIcon /></div>
                    <div className="stat-value">{weeklySummary.data?.total_minutes ?? 0}</div>
                    <div className="stat-label">Minutes Trained</div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon" aria-hidden><ChartBarIcon /></div>
                    <div className="stat-value">{listPlansFx.data?.count ?? 0}</div>
                    <div className="stat-label">Total Plans</div>
                  </div>
                </>
              )}
            </section>

            <section className="card">
              {weeklySummary.loading ? (
                <WeeklyTrackerSkeleton />
              ) : (
                <WeeklyTracker 
                  summary={weeklySummary.data} 
                  plannedWorkoutsPerWeek={generatedPlan?.days_per_week}
                />
              )}
            </section>

            <section className="grid two">
              <div className="card">
                <h2>System Health</h2>
                <div className="row">
                  <button onClick={() => health.run('/health')} disabled={health.loading}>
                    {health.loading ? 'Checking…' : 'Refresh Health'}
                  </button>
                  <span className={`status ${health.error ? 'err' : 'ok'}`}>
                    {health.error ? `ERR: ${health.error}` : health.data ? `OK (${health.data.status})` : ''}
                  </span>
                </div>
              </div>

              <div className="card">
                <h2>Database Status</h2>
                <div className="row">
                  <button onClick={() => dbping.run('/v1/db/ping')} disabled={dbping.loading}>
                    {dbping.loading ? 'Pinging…' : 'Ping DB'}
                  </button>
                  <span className={`status ${dbping.error ? 'err' : 'ok'}`}>
                    {dbping.error ? `ERR: ${dbping.error}` : dbping.data ? `OK (db=${dbping.data.db})` : ''}
                  </span>
                </div>
              </div>
            </section>
          </>
        )}

        {route === 'history' && (
          <History exercises={exercises.data?.items ?? []} />
        )}

        {route === 'exercises' && (
          <section className="card">
            <h2>Exercises Catalog</h2>
            <div className="row">
              <button onClick={() => exercises.run('/v1/exercises')} disabled={exercises.loading}>
                {exercises.loading ? 'Loading…' : 'Refresh'}
              </button>
            </div>
            <div className="list">
              {(exercises.data?.items ?? []).map((x) => (
                <div key={x.id} className="list-item">
                  <div className="list-title">{x.name}</div>
                  <div className="list-sub">{x.primary_muscle} • {x.difficulty}</div>
                </div>
              ))}
            </div>
          </section>
        )}
      </main>

      <footer>
        <small>Develop by Yair Damri</small>
      </footer>
    </div>
  )
}
