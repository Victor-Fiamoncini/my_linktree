// @vitest-environment jsdom

import { render, screen, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import TelemetryFeed from '@/components/telemetry-feed'

const jsonResponse = data => ({ ok: true, json: async () => data })

describe('TelemetryFeed', () => {
	beforeEach(() => {
		global.fetch = vi.fn()
	})

	afterEach(() => {
		vi.restoreAllMocks()
		vi.useRealTimers()
	})

	it('shows a loading state initially', () => {
		global.fetch.mockImplementationOnce(() => new Promise(() => {}))

		render(<TelemetryFeed />)

		expect(screen.getByText(/loading live telemetry/i)).toBeInTheDocument()
	})

	it('shows connections after a successful fetch', async () => {
		global.fetch.mockResolvedValueOnce(jsonResponse([{ tool: 'get_resume', timestamp: '2026-03-02T12:00:00.000Z' }]))

		render(<TelemetryFeed />)

		await waitFor(() => {
			expect(screen.getByText('get_resume')).toBeInTheDocument()
		})
	})

	it('shows an empty state when there are no connections', async () => {
		global.fetch.mockResolvedValueOnce(jsonResponse([]))

		render(<TelemetryFeed />)

		await waitFor(() => {
			expect(screen.getByText(/no agent connections yet/i)).toBeInTheDocument()
		})
	})

	it('shows an error state when the request fails', async () => {
		global.fetch.mockResolvedValueOnce({ ok: false })

		render(<TelemetryFeed />)

		await waitFor(() => {
			expect(screen.getByText(/something went wrong/i)).toBeInTheDocument()
		})
	})

	it('shows an error state when fetch throws', async () => {
		global.fetch.mockRejectedValueOnce(new Error('Network error'))

		render(<TelemetryFeed />)

		await waitFor(() => {
			expect(screen.getByText(/something went wrong/i)).toBeInTheDocument()
		})
	})

	it('polls again after the interval elapses', async () => {
		vi.useFakeTimers()
		global.fetch.mockResolvedValue(jsonResponse([]))

		render(<TelemetryFeed />)

		await vi.waitFor(() => expect(global.fetch).toHaveBeenCalledTimes(1))

		await vi.advanceTimersByTimeAsync(5000)

		expect(global.fetch).toHaveBeenCalledTimes(2)
	})
})
