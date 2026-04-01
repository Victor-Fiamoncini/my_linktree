import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

// Fake sliding-window backed by an in-memory store so the real UpstashRateLimiter
// class is exercised without a real Redis connection.
class FakeSlidingWindow {
	#maxRequests
	#windowMs
	#store = new Map()

	constructor(maxRequests, windowMs) {
		this.#maxRequests = maxRequests
		this.#windowMs = windowMs
	}

	async limit(identifier) {
		const now = Date.now()
		const timestamps = (this.#store.get(identifier) ?? []).filter(t => now - t < this.#windowMs)

		if (timestamps.length >= this.#maxRequests) {
			this.#store.set(identifier, timestamps)
			return { success: false }
		}

		this.#store.set(identifier, [...timestamps, now])
		return { success: true }
	}
}

const WINDOW_FACTORS = { ms: 1, s: 1_000, m: 60_000, h: 3_600_000, d: 86_400_000 }

function parseWindow(window) {
	const [, n, unit] = window.match(/^(\d+)\s*(ms|s|m|h|d)$/)
	return Number(n) * WINDOW_FACTORS[unit]
}

vi.mock('@upstash/ratelimit', () => ({
	Ratelimit: class {
		#impl

		static slidingWindow(maxRequests, window) {
			return { maxRequests, windowMs: parseWindow(window) }
		}

		constructor({ limiter }) {
			this.#impl = new FakeSlidingWindow(limiter.maxRequests, limiter.windowMs)
		}

		limit(identifier) {
			return this.#impl.limit(identifier)
		}
	},
}))

vi.mock('@upstash/redis', () => ({
	Redis: class {},
}))

// Mock only the mailer — UpstashRateLimiter is intentionally NOT mocked here
const mockSendEmail = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/mailer/resend-mailer', () => ({
	ResendMailer: class {
		constructor() {
			this.sendEmail = mockSendEmail
		}
	},
}))

const makeRequest = (body, headers = {}) =>
	new Request('http://localhost/api/contact', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json', ...headers },
		body: JSON.stringify(body),
	})

const ip = addr => ({ 'x-forwarded-for': addr })
const validBody = { name: 'John Doe', email: 'john@example.com', message: 'Hello!' }

describe.skip('UpstashRateLimiter integration with POST /api/contact — disabled: rate limiter commented out', () => {
	let POST

	beforeEach(async () => {
		vi.useFakeTimers()
		vi.resetModules() // forces route.js to re-execute, creating a fresh UpstashRateLimiter instance

		mockSendEmail.mockReset()
		mockSendEmail.mockResolvedValue(undefined)

		process.env.RESEND_API_KEY = 'test-api-key'
		process.env.SENDER_EMAIL = 'sender@example.com'
		process.env.RECIPIENT_EMAIL = 'recipient@example.com'

		const module = await import('@/app/api/contact/route')
		POST = module.POST
	})

	afterEach(() => {
		vi.useRealTimers()
	})

	it('allows requests up to the configured limit (2 per 10 min)', async () => {
		for (let i = 0; i < 2; i++) {
			const response = await POST(makeRequest(validBody, ip('1.2.3.4')))
			expect(response.status).toBe(204)
		}
	})

	it('blocks the 3rd request from the same IP within the window', async () => {
		for (let i = 0; i < 2; i++) {
			await POST(makeRequest(validBody, ip('1.2.3.4')))
		}

		const response = await POST(makeRequest(validBody, ip('1.2.3.4')))
		expect(response.status).toBe(429)
	})

	it('returns a TooManyRequestsError body when rate limited', async () => {
		for (let i = 0; i < 2; i++) {
			await POST(makeRequest(validBody, ip('1.2.3.4')))
		}

		const response = await POST(makeRequest(validBody, ip('1.2.3.4')))
		const body = await response.json()

		expect(body).toMatchObject({
			name: 'TooManyRequestsError',
			message: 'Too many requests',
		})
	})

	it('does not send email when rate limited', async () => {
		for (let i = 0; i < 2; i++) {
			await POST(makeRequest(validBody, ip('1.2.3.4')))
		}

		mockSendEmail.mockClear()
		await POST(makeRequest(validBody, ip('1.2.3.4')))

		expect(mockSendEmail).not.toHaveBeenCalled()
	})

	it('allows requests again after the window (10 min) expires', async () => {
		for (let i = 0; i < 2; i++) {
			await POST(makeRequest(validBody, ip('1.2.3.4')))
		}

		vi.advanceTimersByTime(10 * 60 * 1000 + 1)

		const response = await POST(makeRequest(validBody, ip('1.2.3.4')))
		expect(response.status).toBe(204)
	})

	it('uses a sliding window — partially expired timestamps free up slots', async () => {
		// Use up 1 slot at t=0
		await POST(makeRequest(validBody, ip('1.2.3.4')))

		vi.advanceTimersByTime(5 * 60 * 1000) // t=5 min

		// Use up the remaining 1 slot — limit reached at t=5 min
		await POST(makeRequest(validBody, ip('1.2.3.4')))

		// Still blocked (t=0 entry not yet expired)
		expect((await POST(makeRequest(validBody, ip('1.2.3.4')))).status).toBe(429)

		vi.advanceTimersByTime(5 * 60 * 1000 + 1) // t=10 min 1ms — the t=0 entry expired

		// The slot from t=0 is gone; only the 1 from t=5 min remains — allowed again
		const response = await POST(makeRequest(validBody, ip('1.2.3.4')))
		expect(response.status).toBe(204)
	})

	it('tracks different IPs independently', async () => {
		for (let i = 0; i < 2; i++) {
			await POST(makeRequest(validBody, ip('1.2.3.4')))
		}

		expect((await POST(makeRequest(validBody, ip('1.2.3.4')))).status).toBe(429)
		expect((await POST(makeRequest(validBody, ip('5.6.7.8')))).status).toBe(204)
	})

	it('reads the IP from x-real-ip when x-forwarded-for is absent', async () => {
		for (let i = 0; i < 2; i++) {
			await POST(makeRequest(validBody, { 'x-real-ip': '9.9.9.9' }))
		}

		const response = await POST(makeRequest(validBody, { 'x-real-ip': '9.9.9.9' }))
		expect(response.status).toBe(429)
	})

	it('skips rate limiting when no IP header is present', async () => {
		for (let i = 0; i < 10; i++) {
			const response = await POST(makeRequest(validBody))
			expect(response.status).toBe(204)
		}
	})
})
