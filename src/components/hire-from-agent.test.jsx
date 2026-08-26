// @vitest-environment jsdom

import { render, screen, waitFor, act, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import HireFromAgent from '@/components/hire-from-agent'

describe('HireFromAgent', () => {
	let user
	let writeTextSpy

	beforeEach(() => {
		// userEvent.setup() installs its own clipboard stub on navigator.clipboard,
		// so the spy must be attached to it after setup, not before.
		user = userEvent.setup()
		writeTextSpy = vi.spyOn(navigator.clipboard, 'writeText').mockResolvedValue(undefined)
	})

	afterEach(() => {
		vi.restoreAllMocks()
	})

	it('renders the heading', () => {
		render(<HireFromAgent />)

		expect(screen.getByRole('heading', { name: /hire me from your agent/i })).toBeInTheDocument()
	})

	it('renders the MCP endpoint in the snippet', () => {
		render(<HireFromAgent />)

		expect(screen.getByText(/https:\/\/www\.victorfiamon\.com\.br\/api\/mcp/)).toBeInTheDocument()
	})

	it('renders the copy button', () => {
		render(<HireFromAgent />)

		expect(screen.getByRole('button', { name: /copy/i })).toBeInTheDocument()
	})

	it('copies the snippet to the clipboard when clicked', async () => {
		render(<HireFromAgent />)

		await user.click(screen.getByRole('button', { name: /copy/i }))

		expect(writeTextSpy).toHaveBeenCalledWith(expect.stringContaining('AGENTS.md'))
	})

	it('shows a "Copied!" confirmation after copying', async () => {
		render(<HireFromAgent />)

		await user.click(screen.getByRole('button', { name: /copy/i }))

		await waitFor(() => {
			expect(screen.getByRole('button', { name: /copied!/i })).toBeInTheDocument()
		})
	})

	it('reverts to "Copy" after the confirmation times out', async () => {
		vi.useFakeTimers()
		render(<HireFromAgent />)

		await act(async () => {
			fireEvent.click(screen.getByRole('button', { name: /copy/i }))
			await Promise.resolve()
			await Promise.resolve()
		})

		expect(screen.getByRole('button', { name: /copied!/i })).toBeInTheDocument()

		act(() => {
			vi.advanceTimersByTime(2000)
		})

		expect(screen.getByRole('button', { name: /^copy$/i })).toBeInTheDocument()

		vi.useRealTimers()
	})
})
