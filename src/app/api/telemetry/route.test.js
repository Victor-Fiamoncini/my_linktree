import { describe, it, expect, vi, beforeEach } from 'vitest'

import { GET } from '@/app/api/telemetry/route'

const mockListRecent = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/telemetry/upstash-connection-log', () => ({
	UpstashConnectionLog: class {
		constructor() {
			this.listRecent = mockListRecent
		}
	},
}))

describe('GET /api/telemetry', () => {
	beforeEach(() => {
		mockListRecent.mockReset()
	})

	it('returns 200 with the recent connections', async () => {
		const connections = [{ tool: 'get_resume', timestamp: '2026-03-02T12:00:00.000Z' }]
		mockListRecent.mockResolvedValue(connections)

		const response = await GET()
		const body = await response.json()

		expect(response.status).toBe(200)
		expect(body).toEqual(connections)
	})

	it('returns an empty array when there are no connections', async () => {
		mockListRecent.mockResolvedValue([])

		const response = await GET()
		const body = await response.json()

		expect(body).toEqual([])
	})

	it('returns 500 when the connection log throws', async () => {
		mockListRecent.mockRejectedValue(new Error('Redis failure'))
		vi.spyOn(console, 'error').mockImplementation(() => {})

		const response = await GET()

		expect(response.status).toBe(500)
	})

	it('returns an InternalServerError body when the connection log throws', async () => {
		mockListRecent.mockRejectedValue(new Error('Redis failure'))
		vi.spyOn(console, 'error').mockImplementation(() => {})

		const response = await GET()
		const body = await response.json()

		expect(body).toMatchObject({ name: 'InternalServerError', message: 'Internal Server Error' })
	})
})
