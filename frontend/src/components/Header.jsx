import React from 'react'
import { LogoIcon, WandIcon, DumbbellIcon, HomeIcon, BookIcon, ChartBarIcon } from './icons'

const NAV_ITEMS = [
  { id: 'generator', label: 'Generator', href: '#/generator' },
  { id: 'workouts', label: 'Workouts', href: '#/workouts' },
  { id: 'dashboard', label: 'Dashboard', href: '#/dashboard' },
  { id: 'history', label: 'History', href: '#/history' },
  { id: 'exercises', label: 'Exercises', href: '#/exercises' },
]

const ICONS = {
  generator: WandIcon,
  workouts: DumbbellIcon,
  dashboard: HomeIcon,
  history: ChartBarIcon,
  exercises: BookIcon,
}

export default function Header({ active, user, onSignOut }) {
  return (
    <header className="site-header">
      <a className="skip-link" href="#main">Skip to content</a>
      <div className="header-inner">
        <div className="brand">
          <LogoIcon className="brand-icon" />
          <span className="brand-name">Workout Planner</span>
        </div>
        <nav className="site-nav" aria-label="Primary">
          <ul className="nav-list" role="list">
            {NAV_ITEMS.map(item => (
              <li key={item.id} className="nav-item">
                <a
                  className={`nav-link ${active === item.id ? 'active' : ''}`}
                  href={item.href}
                  aria-current={active === item.id ? 'page' : undefined}
                >
                  {(() => { const Icon = ICONS[item.id]; return <Icon className="nav-icon" /> })()}
                  <span className="nav-label">{item.label}</span>
                </a>
              </li>
            ))}
          </ul>
        </nav>

        <div className="header-actions">
          {user ? (
            <>
              <div className="user-chip" title={user.email}>
                <span className="user-initials" aria-hidden>{(user.name || user.email || '?').slice(0,1).toUpperCase()}</span>
                <span className="user-name">{user.name || user.email}</span>
              </div>
              <button className="signout-button" type="button" onClick={onSignOut}>Sign out</button>
            </>
          ) : (
            <div className="auth-links">
              <a className="nav-link" href="#/login">Login</a>
              <a className="nav-link" href="#/register">Register</a>
            </div>
          )}
        </div>
      </div>
    </header>
  )
}
