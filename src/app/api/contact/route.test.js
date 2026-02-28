import { describe, it, expect, vi, beforeEach } from 'vitest'

import { POST } from '@/app/api/contact/route'

const mockSendEmail = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/mailer/resend-mailer', () => ({
	ResendMailer: class {
		constructor() {
			this.sendEmail = mockSendEmail
		}
	},
}))

const makeRequest = body =>
	new Request('http://localhost/api/contact', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(body),
	})

describe('POST /api/contact', () => {
	beforeEach(() => {
		mockSendEmail.mockReset()
		mockSendEmail.mockResolvedValue(undefined)

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
})
