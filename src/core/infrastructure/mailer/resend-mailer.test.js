import { describe, it, expect, vi, beforeEach } from 'vitest'

import { ResendMailer } from '@/core/infrastructure/mailer/resend-mailer'

const mockSend = vi.hoisted(() => vi.fn())

vi.mock('resend', () => ({
	Resend: class {
		constructor() {
			this.emails = { send: mockSend }
		}
	},
}))

describe('ResendMailer', () => {
	let mailer

	beforeEach(() => {
		mockSend.mockReset()
		mockSend.mockResolvedValue(undefined)
		mailer = new ResendMailer({ resendApiKey: 'test-api-key' })
	})

	it('calls resend.emails.send with the correct parameters', async () => {
		const emailParams = {
			from: 'sender@example.com',
			to: 'recipient@example.com',
			subject: 'Test subject',
			html: '<p>Test message</p>',
		}

		await mailer.sendEmail(emailParams)

		expect(mockSend).toHaveBeenCalledOnce()
		expect(mockSend).toHaveBeenCalledWith(emailParams)
	})

	it('propagates errors thrown by the Resend API', async () => {
		const apiError = new Error('Resend API error')
		mockSend.mockRejectedValueOnce(apiError)

		await expect(
			mailer.sendEmail({ from: 'a@example.com', to: 'b@example.com', subject: 'Test', html: '<p>Test</p>' })
		).rejects.toThrow(apiError)
	})
})
