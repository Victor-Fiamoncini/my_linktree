import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import { ConsoleMailer } from '@/core/infrastructure/mailer/console-mailer'

describe('ConsoleMailer', () => {
	let mailer
	let consoleLogSpy

	beforeEach(() => {
		mailer = new ConsoleMailer()
		consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
	})

	afterEach(() => {
		consoleLogSpy.mockRestore()
	})

	it('logs the email instead of sending it', async () => {
		await mailer.sendEmail({
			from: 'sender@example.com',
			to: 'recipient@example.com',
			subject: 'Test subject',
			html: '<p>Test message</p>',
		})

		expect(consoleLogSpy).toHaveBeenCalledOnce()
		expect(consoleLogSpy.mock.calls[0][0]).toContain('sender@example.com')
		expect(consoleLogSpy.mock.calls[0][0]).toContain('recipient@example.com')
		expect(consoleLogSpy.mock.calls[0][0]).toContain('Test subject')
		expect(consoleLogSpy.mock.calls[0][0]).toContain('<p>Test message</p>')
	})
})
