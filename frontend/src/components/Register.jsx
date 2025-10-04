import React, { useState } from 'react'

export default function Register({ onSuccess }) {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const submit = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    try {
      const res = await fetch('/v1/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, password }),
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
    <section className="card" aria-labelledby="register-title">
      <h2 id="register-title">Create Account</h2>
      {error && <div role="alert" className="error-message">Error: {error}</div>}
      <form onSubmit={submit} className="form-grid" style={{ marginTop: 12 }}>
        <div>
          <label htmlFor="reg-name" className="input-label">Name</label>
          <input
            id="reg-name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            autoComplete="name"
          />
        </div>
        <div>
          <label htmlFor="reg-email" className="input-label">Email</label>
          <input
            id="reg-email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoComplete="email"
          />
        </div>
        <div>
          <label htmlFor="reg-password" className="input-label">Password</label>
          <input
            id="reg-password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoComplete="new-password"
          />
        </div>
        <div className="row" style={{ alignItems: 'flex-end' }}>
          <button type="submit" className="action-button primary" disabled={loading || !email || !password}>
            {loading ? 'Creating…' : 'Create account'}
          </button>
          <a href="#/login" className="action-button secondary" role="button" aria-label="Go to login">
            Sign in instead
          </a>
        </div>
      </form>
    </section>
  )
}
