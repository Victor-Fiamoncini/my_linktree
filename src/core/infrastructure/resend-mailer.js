import { Resend } from 'resend'

export class ResendMailer {
	#resend

	constructor({ resendApiKey }) {
		this.#resend = new Resend(resendApiKey)
	}

	async sendEmail({ from, to, subject, html }) {
		await this.#resend.emails.send({ from, to, subject, html })
	}
}
