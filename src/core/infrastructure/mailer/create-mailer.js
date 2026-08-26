import { ConsoleMailer } from '@/core/infrastructure/mailer/console-mailer'
import { ResendMailer } from '@/core/infrastructure/mailer/resend-mailer'

export function createMailer() {
	if (process.env.MAILER_DRIVER === 'console') {
		return new ConsoleMailer()
	}

	return new ResendMailer({ resendApiKey: process.env.MAILER_RESEND_API_KEY })
}
