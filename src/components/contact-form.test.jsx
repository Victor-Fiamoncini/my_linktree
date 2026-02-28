// @vitest-environment jsdom

import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import ContactForm from '@/components/contact-form'

describe('ContactForm', () => {
	beforeEach(() => {
		global.fetch = vi.fn()
	})

	afterEach(() => {
		vi.restoreAllMocks()
	})

	describe('initial render', () => {
		it('renders all form fields', () => {
			render(<ContactForm />)

			expect(screen.getByLabelText(/^name$/i)).toBeInTheDocument()
			expect(screen.getByLabelText(/^email$/i)).toBeInTheDocument()
			expect(screen.getByLabelText(/^message$/i)).toBeInTheDocument()
		})

		it('all inputs are initially empty', () => {
			render(<ContactForm />)

			expect(screen.getByLabelText(/^name$/i)).toHaveValue('')
			expect(screen.getByLabelText(/^email$/i)).toHaveValue('')
			expect(screen.getByLabelText(/^message$/i)).toHaveValue('')
		})

		it('renders the submit button', () => {
			render(<ContactForm />)

			expect(screen.getByRole('button', { name: /reach out/i })).toBeInTheDocument()
		})
	})

	describe('form field interactions', () => {
		it('allows typing in the name field', async () => {
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')

			expect(screen.getByLabelText(/^name$/i)).toHaveValue('John Doe')
		})

		it('allows typing in the email field', async () => {
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')

			expect(screen.getByLabelText(/^email$/i)).toHaveValue('john@example.com')
		})

		it('allows typing in the message field', async () => {
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^message$/i), 'Hello there!')

			expect(screen.getByLabelText(/^message$/i)).toHaveValue('Hello there!')
		})
	})

	describe('submit button disabled state', () => {
		it('is disabled when all fields are empty', () => {
			render(<ContactForm />)

			expect(screen.getByRole('button', { name: /reach out/i })).toBeDisabled()
		})

		it('is disabled when only name is filled', async () => {
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')

			expect(screen.getByRole('button', { name: /reach out/i })).toBeDisabled()
		})

		it('is disabled when only email is filled', async () => {
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')

			expect(screen.getByRole('button', { name: /reach out/i })).toBeDisabled()
		})

		it('is disabled when only message is filled', async () => {
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')

			expect(screen.getByRole('button', { name: /reach out/i })).toBeDisabled()
		})

		it('is disabled when name and email are filled but message is missing', async () => {
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')

			expect(screen.getByRole('button', { name: /reach out/i })).toBeDisabled()
		})

		it('is enabled when all fields are filled', async () => {
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')

			expect(screen.getByRole('button', { name: /reach out/i })).toBeEnabled()
		})
	})

	describe('form submission - sending state', () => {
		it('shows Sending... text and disables button while awaiting response', async () => {
			const user = userEvent.setup()
			let resolveFetch
			global.fetch = vi.fn().mockImplementationOnce(
				() =>
					new Promise(resolve => {
						resolveFetch = resolve
					})
			)
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')

			user.click(screen.getByRole('button', { name: /reach out/i }))

			await waitFor(() => {
				expect(screen.getByRole('button', { name: /sending\.\.\./i })).toBeDisabled()
			})

			resolveFetch({ ok: true })

			await waitFor(() => {
				expect(screen.getByText(/thank you for your message/i)).toBeInTheDocument()
			})
		})
	})

	describe('form submission - success', () => {
		it('shows success message after successful submission', async () => {
			global.fetch = vi.fn().mockResolvedValueOnce({ ok: true })
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')
			await user.click(screen.getByRole('button', { name: /reach out/i }))

			await waitFor(() => {
				expect(screen.getByText(/thank you for your message/i)).toBeInTheDocument()
			})
		})

		it('clears all form fields after successful submission', async () => {
			global.fetch = vi.fn().mockResolvedValueOnce({ ok: true })
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')
			await user.click(screen.getByRole('button', { name: /reach out/i }))

			await waitFor(() => {
				expect(screen.getByText(/thank you for your message/i)).toBeInTheDocument()
			})

			expect(screen.getByLabelText(/^name$/i)).toHaveValue('')
			expect(screen.getByLabelText(/^email$/i)).toHaveValue('')
			expect(screen.getByLabelText(/^message$/i)).toHaveValue('')
		})

		it('hides the submit button after successful submission', async () => {
			global.fetch = vi.fn().mockResolvedValueOnce({ ok: true })
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')
			await user.click(screen.getByRole('button', { name: /reach out/i }))

			await waitFor(() => {
				expect(screen.queryByRole('button')).not.toBeInTheDocument()
			})
		})

		it('sends correct data to the API endpoint', async () => {
			global.fetch = vi.fn().mockResolvedValueOnce({ ok: true })
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')
			await user.click(screen.getByRole('button', { name: /reach out/i }))

			await waitFor(() => {
				expect(global.fetch).toHaveBeenCalledWith('/api/contact', {
					method: 'POST',
					headers: { 'Content-Type': 'application/json' },
					body: JSON.stringify({ name: 'John Doe', email: 'john@example.com', message: 'Hello!' }),
				})
			})
		})
	})

	describe('form submission - error', () => {
		it('shows error message when API returns a non-ok response', async () => {
			global.fetch = vi.fn().mockResolvedValueOnce({ ok: false })
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')
			await user.click(screen.getByRole('button', { name: /reach out/i }))

			await waitFor(() => {
				expect(screen.getByText(/oops! something went wrong/i)).toBeInTheDocument()
			})
		})

		it('shows error message when fetch throws a network error', async () => {
			global.fetch = vi.fn().mockRejectedValueOnce(new Error('Network error'))
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')
			await user.click(screen.getByRole('button', { name: /reach out/i }))

			await waitFor(() => {
				expect(screen.getByText(/oops! something went wrong/i)).toBeInTheDocument()
			})
		})

		it('preserves form field values after a failed submission', async () => {
			global.fetch = vi.fn().mockResolvedValueOnce({ ok: false })
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')
			await user.click(screen.getByRole('button', { name: /reach out/i }))

			await waitFor(() => {
				expect(screen.getByText(/oops! something went wrong/i)).toBeInTheDocument()
			})

			expect(screen.getByLabelText(/^name$/i)).toHaveValue('John Doe')
			expect(screen.getByLabelText(/^email$/i)).toHaveValue('john@example.com')
			expect(screen.getByLabelText(/^message$/i)).toHaveValue('Hello!')
		})

		it('does not show the success message on error', async () => {
			global.fetch = vi.fn().mockResolvedValueOnce({ ok: false })
			const user = userEvent.setup()
			render(<ContactForm />)

			await user.type(screen.getByLabelText(/^name$/i), 'John Doe')
			await user.type(screen.getByLabelText(/^email$/i), 'john@example.com')
			await user.type(screen.getByLabelText(/^message$/i), 'Hello!')
			await user.click(screen.getByRole('button', { name: /reach out/i }))

			await waitFor(() => {
				expect(screen.getByText(/oops! something went wrong/i)).toBeInTheDocument()
			})

			expect(screen.queryByText(/thank you for your message/i)).not.toBeInTheDocument()
		})
	})
})
