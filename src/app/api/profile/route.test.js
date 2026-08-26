import { describe, it, expect, vi, beforeEach } from 'vitest'

import { GET } from '@/app/api/profile/route'

const mockGetProfile = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/database/memory-database', () => ({
	MemoryDatabase: class {
		constructor() {
			this.getProfile = mockGetProfile
		}
	},
}))

describe('GET /api/profile', () => {
	beforeEach(() => {
		mockGetProfile.mockReset()
	})

	it('returns 200 with the profile as JSON', async () => {
		const profile = { name: 'Victor Fiamoncini', experiences: [], education: [] }
		mockGetProfile.mockResolvedValue(profile)

		const response = await GET()
		const body = await response.json()

		expect(response.status).toBe(200)
		expect(response.headers.get('content-type')).toContain('application/json')
		expect(body).toEqual(profile)
	})

	it('returns 500 when the database throws', async () => {
		mockGetProfile.mockRejectedValue(new Error('Database failure'))
		vi.spyOn(console, 'error').mockImplementation(() => {})

		const response = await GET()

		expect(response.status).toBe(500)
	})

	it('returns an InternalServerError body when the database throws', async () => {
		mockGetProfile.mockRejectedValue(new Error('Database failure'))
		vi.spyOn(console, 'error').mockImplementation(() => {})

		const response = await GET()
		const body = await response.json()

		expect(body).toMatchObject({ name: 'InternalServerError', message: 'Internal Server Error' })
	})
})
