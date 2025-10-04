import React, { useState } from 'react'

export default function Login({ onSuccess }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const submit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      const res = await fetch('/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      })
      const text = await res.text()
      const json = text ? JSON.parse(text) : null
      if (!res.ok) throw new Error(json?.detail || res.statusText)
      onSuccess?.(json)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <section className="card" aria-labelledby="login-title">
      <h2 id="login-title">Login</h2>
      {error && <div role="alert" className="error-message">Error: {error}</div>}
      <form onSubmit={submit} className="form-grid" style={{ marginTop: 12 }}>
        <div>
          <label htmlFor="login-email" className="input-label">Email</label>
          <input
            id="login-email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoComplete="email"
          />
        </div>
        <div>
          <label htmlFor="login-password" className="input-label">Password</label>
          <input
            id="login-password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoComplete="current-password"
          />
        </div>
        <div className="row" style={{ alignItems: 'flex-end' }}>
          <button type="submit" className="action-button primary" disabled={loading || !email || !password}>
            {loading ? 'Signing in…' : 'Sign in'}
          </button>
          <a href="#/register" className="action-button secondary" role="button" aria-label="Go to register">
            Create account
          </a>
        </div>
      </form>
    </section>
  )
}
