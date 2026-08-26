import { MissingRequiredFieldsError, SlotUnavailableError } from '@/core/infrastructure/errors'

import { CheckAvailabilityUseCase } from './check-availability-use-case'

export class ScheduleMeetingUseCase {
	#bookingStore
	#checkAvailabilityUseCase
	#mailer
	#senderEmail
	#recipientEmail

	constructor({ bookingStore, availabilityConfig, mailer, senderEmail, recipientEmail }) {
		this.#bookingStore = bookingStore
		this.#checkAvailabilityUseCase = new CheckAvailabilityUseCase({ bookingStore, availabilityConfig })
		this.#mailer = mailer
		this.#senderEmail = senderEmail
		this.#recipientEmail = recipientEmail
	}

	async execute({ name, email, company, slotStart }) {
		if (!name || !email || !slotStart) {
			throw new MissingRequiredFieldsError()
		}

		const { slots } = await this.#checkAvailabilityUseCase.execute()

		if (!slots.includes(slotStart)) {
			throw new SlotUnavailableError()
		}

		const booking = { name, email, company: company ?? null, slotStart }

		await this.#bookingStore.book({ slotStartEpochMs: new Date(slotStart).getTime(), booking })

		await this.#mailer.sendEmail({
			from: this.#senderEmail,
			to: email,
			subject: 'My Linktree - Meeting scheduled',
			html: `
				<p>Hi ${name},</p>
				<p>Your meeting with Victor Fiamoncini is confirmed for ${slotStart}.</p>
			`,
		})

		await this.#mailer.sendEmail({
			from: this.#senderEmail,
			to: this.#recipientEmail,
			subject: `My Linktree - New meeting booked by ${name}`,
			html: `
				<p>Name: ${name}</p>
				<p>Email: ${email}</p>
				<p>Company: ${company ?? '-'}</p>
				<p>Slot: ${slotStart}</p>
			`,
		})

		return booking
	}
}
