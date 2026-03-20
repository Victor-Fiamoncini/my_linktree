import { describe, it, expect, vi, beforeEach } from 'vitest'

import { POST } from '@/app/api/contact/route'

const mockSendEmail = vi.hoisted(() => vi.fn())
const mockIsAllowed = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/mailer/resend-mailer', () => ({
	ResendMailer: class {
		constructor() {
			this.sendEmail = mockSendEmail
		}
	},
}))

vi.mock('@/core/infrastructure/rate-limiter/upstash-rate-limiter', () => ({
	UpstashRateLimiter: class {
		constructor() {
			this.isAllowed = mockIsAllowed
		}
	},
}))

const makeRequest = (body, headers = {}) =>
	new Request('http://localhost/api/contact', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json', ...headers },
		body: JSON.stringify(body),
	})

describe('POST /api/contact', () => {
	beforeEach(() => {
		mockSendEmail.mockReset()
		mockSendEmail.mockResolvedValue(undefined)

		mockIsAllowed.mockReset()
		mockIsAllowed.mockResolvedValue(true)

		process.env.RESEND_API_KEY = 'test-api-key'
		process.env.SENDER_EMAIL = 'sender@example.com'
		process.env.RECIPIENT_EMAIL = 'recipient@example.com'
	})

	describe('successful submission', () => {
		it('returns 204 with no body when all fields are provided', async () => {
			const request = makeRequest({ name: 'John Doe', email: 'john@example.com', message: 'Hello!' })
			const response = await POST(request)

			expect(response.status).toBe(204)
			expect(response.body).toBeNull()
		})

		it('calls sendEmail with the correct parameters', async () => {
			const request = makeRequest({ name: 'John Doe', email: 'john@example.com', message: 'Hello!' })
			await POST(request)

			expect(mockSendEmail).toHaveBeenCalledOnce()
			expect(mockSendEmail).toHaveBeenCalledWith({
				from: 'sender@example.com',
				to: 'recipient@example.com',
				subject: 'My Linktree - New contact from John Doe',
				html: expect.stringContaining('John Doe'),
			})
		})

		it('includes name, email and message in the email HTML', async () => {
			const request = makeRequest({ name: 'Jane Doe', email: 'jane@example.com', message: 'Hi there!' })
			await POST(request)

			const { html } = mockSendEmail.mock.calls[0][0]
			expect(html).toContain('Jane Doe')
			expect(html).toContain('jane@example.com')
			expect(html).toContain('Hi there!')
		})
	})

	describe('validation errors (400)', () => {
		it('returns 400 when name is missing', async () => {
			const request = makeRequest({ email: 'john@example.com', message: 'Hello!' })
			const response = await POST(request)

			expect(response.status).toBe(400)
		})

		it('returns 400 when email is missing', async () => {
			const request = makeRequest({ name: 'John Doe', message: 'Hello!' })
			const response = await POST(request)

			expect(response.status).toBe(400)
		})

		it('returns 400 when message is missing', async () => {
			const request = makeRequest({ name: 'John Doe', email: 'john@example.com' })
			const response = await POST(request)

			expect(response.status).toBe(400)
		})

		it('returns 400 when all fields are missing', async () => {
			const request = makeRequest({})
			const response = await POST(request)

			expect(response.status).toBe(400)
		})

		it('returns a MissingRequiredFieldsError body on validation failure', async () => {
			const request = makeRequest({ email: 'john@example.com', message: 'Hello!' })
			const response = await POST(request)
			const body = await response.json()

			expect(body).toMatchObject({
				name: 'MissingRequiredFieldsError',
				message: 'Missing required fields',
			})
		})

		it('does not call sendEmail when validation fails', async () => {
			const request = makeRequest({ name: 'John Doe' })
			await POST(request)

			expect(mockSendEmail).not.toHaveBeenCalled()
		})
	})

	describe('email service errors (500)', () => {
		it('returns 500 when the mailer throws an error', async () => {
			mockSendEmail.mockRejectedValueOnce(new Error('Resend API error'))
			vi.spyOn(console, 'error').mockImplementation(() => {})

			const request = makeRequest({ name: 'John Doe', email: 'john@example.com', message: 'Hello!' })
			const response = await POST(request)

			expect(response.status).toBe(500)
		})

		it('returns an InternalServerError body when the mailer throws', async () => {
			mockSendEmail.mockRejectedValueOnce(new Error('Resend API error'))
			vi.spyOn(console, 'error').mockImplementation(() => {})

			const request = makeRequest({ name: 'John Doe', email: 'john@example.com', message: 'Hello!' })
			const response = await POST(request)
			const body = await response.json()

			expect(body).toMatchObject({
				name: 'InternalServerError',
				message: 'Internal Server Error',
			})
		})
	})

	describe('rate limiting (429)', () => {
		it('returns 429 when the rate limiter blocks the request', async () => {
			mockIsAllowed.mockResolvedValue(false)

			const request = makeRequest(
				{ name: 'John Doe', email: 'john@example.com', message: 'Hello!' },
				{ 'x-forwarded-for': '1.2.3.4' }
			)
			const response = await POST(request)

			expect(response.status).toBe(429)
		})

		it('returns a TooManyRequestsError body when rate limited', async () => {
			mockIsAllowed.mockResolvedValue(false)

			const request = makeRequest(
				{ name: 'John Doe', email: 'john@example.com', message: 'Hello!' },
				{ 'x-forwarded-for': '1.2.3.4' }
			)
			const response = await POST(request)
			const body = await response.json()

			expect(body).toMatchObject({
				name: 'TooManyRequestsError',
				message: 'Too many requests',
			})
		})

		it('does not call sendEmail when rate limited', async () => {
			mockIsAllowed.mockResolvedValue(false)

			const request = makeRequest(
				{ name: 'John Doe', email: 'john@example.com', message: 'Hello!' },
				{ 'x-forwarded-for': '1.2.3.4' }
			)
			await POST(request)

			expect(mockSendEmail).not.toHaveBeenCalled()
		})

		it('calls isAllowed with the x-forwarded-for header value', async () => {
			const request = makeRequest(
				{ name: 'John Doe', email: 'john@example.com', message: 'Hello!' },
				{ 'x-forwarded-for': '203.0.113.42' }
			)
			await POST(request)

			expect(mockIsAllowed).toHaveBeenCalledWith('203.0.113.42')
		})

		it('falls back to x-real-ip when x-forwarded-for is absent', async () => {
			const request = makeRequest(
				{ name: 'John Doe', email: 'john@example.com', message: 'Hello!' },
				{ 'x-real-ip': '203.0.113.99' }
			)
			await POST(request)

			expect(mockIsAllowed).toHaveBeenCalledWith('203.0.113.99')
		})

		it('does not call isAllowed when no IP header is present', async () => {
			const request = makeRequest({ name: 'John Doe', email: 'john@example.com', message: 'Hello!' })
			await POST(request)

			expect(mockIsAllowed).not.toHaveBeenCalled()
		})
	})
})
