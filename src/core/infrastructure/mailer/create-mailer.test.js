import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

vi.mock('@/core/infrastructure/mailer/console-mailer', () => ({
	ConsoleMailer: class {
		constructor() {
			this.isConsoleMailer = true
		}
	},
}))

vi.mock('@/core/infrastructure/mailer/resend-mailer', () => ({
	ResendMailer: class {
		constructor() {
			this.isResendMailer = true
		}
	},
}))

const { createMailer } = await import('@/core/infrastructure/mailer/create-mailer')

describe('createMailer', () => {
	const originalDriver = process.env.MAILER_DRIVER

	beforeEach(() => {
		delete process.env.MAILER_DRIVER
	})

	afterEach(() => {
		if (originalDriver === undefined) {
			delete process.env.MAILER_DRIVER
		} else {
			process.env.MAILER_DRIVER = originalDriver
		}
	})

	it('returns a ConsoleMailer when MAILER_DRIVER is "console"', () => {
		process.env.MAILER_DRIVER = 'console'

		expect(createMailer().isConsoleMailer).toBe(true)
	})

	it('returns a ResendMailer by default', () => {
		expect(createMailer().isResendMailer).toBe(true)
	})

	it('returns a ResendMailer for any other MAILER_DRIVER value', () => {
		process.env.MAILER_DRIVER = 'something-else'

		expect(createMailer().isResendMailer).toBe(true)
	})
})
