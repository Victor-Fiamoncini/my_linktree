import { describe, it, expect, vi, beforeEach } from 'vitest'

const mockLimit = vi.hoisted(() => vi.fn())

vi.mock('@upstash/ratelimit', () => ({
	Ratelimit: class {
		static slidingWindow() {}
		constructor() {
			this.limit = mockLimit
		}
	},
}))

vi.mock('@upstash/redis', () => ({
	Redis: { fromEnv: () => ({}) },
}))

import { UpstashRateLimiter } from '@/core/infrastructure/rate-limiter/upstash-rate-limiter'

describe('UpstashRateLimiter', () => {
	let rateLimiter

	beforeEach(() => {
		mockLimit.mockReset()
		rateLimiter = new UpstashRateLimiter({ maxRequests: 5, window: '10 m' })
	})

	it('returns true when Ratelimit allows the request', async () => {
		mockLimit.mockResolvedValue({ success: true })

		const result = await rateLimiter.isAllowed('1.2.3.4')

		expect(result).toBe(true)
	})

	it('returns false when Ratelimit blocks the request', async () => {
		mockLimit.mockResolvedValue({ success: false })

		const result = await rateLimiter.isAllowed('1.2.3.4')

		expect(result).toBe(false)
	})

	it('calls limit with the given identifier', async () => {
		mockLimit.mockResolvedValue({ success: true })

		await rateLimiter.isAllowed('203.0.113.42')

		expect(mockLimit).toHaveBeenCalledWith('203.0.113.42')
	})
})
