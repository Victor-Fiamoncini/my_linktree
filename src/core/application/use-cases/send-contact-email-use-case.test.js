import { describe, it, expect, vi, beforeEach } from 'vitest'

import { SendContactEmailUseCase, MissingRequiredFieldsError } from './send-contact-email-use-case'

describe('SendContactEmailUseCase', () => {
	let mailerMock
	let useCase

	beforeEach(() => {
		mailerMock = {
			sendEmail: vi.fn(),
		}

		useCase = new SendContactEmailUseCase({
			mailer: mailerMock,
			senderEmail: 'sender@example.com',
			recipientEmail: 'recipient@example.com',
		})
	})

	it('should send email with correct parameters', async () => {
		const contactData = {
			name: 'John Doe',
			email: 'john@example.com',
			message: 'Hello, this is a test message',
		}

		await useCase.execute(contactData)

		expect(mailerMock.sendEmail).toHaveBeenCalledWith({
			from: 'sender@example.com',
			to: 'recipient@example.com',
			subject: 'My Linktree - New contact from John Doe',
			html: expect.stringContaining('John Doe'),
		})
	})

	it('should throw MissingRequiredFieldsError when name is missing', async () => {
		await expect(useCase.execute({ email: 'john@example.com', message: 'Test' })).rejects.toThrow(
			MissingRequiredFieldsError
		)
	})

	it('should throw MissingRequiredFieldsError when email is missing', async () => {
		await expect(useCase.execute({ name: 'John Doe', message: 'Test' })).rejects.toThrow(MissingRequiredFieldsError)
	})

	it('should throw MissingRequiredFieldsError when message is missing', async () => {
		await expect(useCase.execute({ name: 'John Doe', email: 'john@example.com' })).rejects.toThrow(
			MissingRequiredFieldsError
		)
	})

	it('should not call mailer when validation fails', async () => {
		await expect(useCase.execute({ name: 'John Doe' })).rejects.toThrow()

		expect(mailerMock.sendEmail).not.toHaveBeenCalled()
	})
})
