export class MissingRequiredFieldsError extends Error {
	constructor() {
		super('Missing required fields')

		this.name = 'MissingRequiredFieldsError'
	}
}

export class SendContactEmailUseCase {
	#mailer
	#senderEmail
	#recipientEmail

	constructor({ mailer, senderEmail, recipientEmail }) {
		this.#mailer = mailer
		this.#senderEmail = senderEmail
		this.#recipientEmail = recipientEmail
	}

	async execute({ name, email, message }) {
		if (!name || !email || !message) {
			throw new MissingRequiredFieldsError()
		}

		await this.#mailer.sendEmail({
			from: this.#senderEmail,
			to: this.#recipientEmail,
			subject: `My Linktree - New contact from ${name}`,
			html: `
				<p>Name: ${name}</p>
				<p>Email: ${email}</p>
				<p>Message: ${message}</p>
			`,
		})
	}
}
