import { render, screen } from '@testing-library/react'
import Login from './Login'

it('renders the login form fields', () => {
  render(<Login onSuccess={() => {}} />)

  expect(screen.getByRole('heading', { name: /login/i })).toBeInTheDocument()
  expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
  expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
})
