import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import { MissingRequiredFieldsError, SlotUnavailableError } from '@/core/infrastructure/errors'

import { ScheduleMeetingUseCase } from '@/core/application/use-cases/schedule-meeting-use-case'

const availabilityConfig = {
	timezone: 'America/Sao_Paulo',
	slotDurationMinutes: 30,
	weeklyWindows: [0, 1, 2, 3, 4, 5, 6].map(weekday => ({ weekday, start: '09:00', end: '10:00' })),
	bookingHorizonDays: 2,
}

const availableSlotStart = '2026-03-02T12:00:00.000Z'

describe('ScheduleMeetingUseCase', () => {
	let bookingStoreMock
	let mailerMock
	let useCase

	beforeEach(() => {
		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T08:00:00.000Z'))

		bookingStoreMock = {
			listUpcoming: vi.fn().mockResolvedValue([]),
			book: vi.fn().mockResolvedValue(undefined),
		}

		mailerMock = {
			sendEmail: vi.fn().mockResolvedValue(undefined),
		}

		useCase = new ScheduleMeetingUseCase({
			bookingStore: bookingStoreMock,
			availabilityConfig,
			mailer: mailerMock,
			senderEmail: 'sender@example.com',
			recipientEmail: 'recipient@example.com',
		})
	})

	afterEach(() => {
		vi.useRealTimers()
	})

	it('books the slot and returns the booking', async () => {
		const result = await useCase.execute({ name: 'John Doe', email: 'john@example.com', slotStart: availableSlotStart })

		expect(result).toEqual({
			name: 'John Doe',
			email: 'john@example.com',
			company: null,
			slotStart: availableSlotStart,
		})
	})

	it('calls bookingStore.book with the slot epoch and booking', async () => {
		await useCase.execute({ name: 'John Doe', email: 'john@example.com', slotStart: availableSlotStart })

		expect(bookingStoreMock.book).toHaveBeenCalledWith({
			slotStartEpochMs: new Date(availableSlotStart).getTime(),
			booking: { name: 'John Doe', email: 'john@example.com', company: null, slotStart: availableSlotStart },
		})
	})

	it('sends a confirmation email to the requester and a notification to the recipient', async () => {
		await useCase.execute({ name: 'John Doe', email: 'john@example.com', slotStart: availableSlotStart })

		expect(mailerMock.sendEmail).toHaveBeenCalledTimes(2)
		expect(mailerMock.sendEmail).toHaveBeenCalledWith(expect.objectContaining({ to: 'john@example.com' }))
		expect(mailerMock.sendEmail).toHaveBeenCalledWith(expect.objectContaining({ to: 'recipient@example.com' }))
	})

	it('throws MissingRequiredFieldsError when name is missing', async () => {
		await expect(useCase.execute({ email: 'john@example.com', slotStart: availableSlotStart })).rejects.toThrow(
			MissingRequiredFieldsError
		)
	})

	it('throws MissingRequiredFieldsError when email is missing', async () => {
		await expect(useCase.execute({ name: 'John Doe', slotStart: availableSlotStart })).rejects.toThrow(
			MissingRequiredFieldsError
		)
	})

	it('throws MissingRequiredFieldsError when slotStart is missing', async () => {
		await expect(useCase.execute({ name: 'John Doe', email: 'john@example.com' })).rejects.toThrow(
			MissingRequiredFieldsError
		)
	})

	it('throws SlotUnavailableError when the slot is outside the availability windows', async () => {
		await expect(
			useCase.execute({ name: 'John Doe', email: 'john@example.com', slotStart: '2026-03-02T20:00:00.000Z' })
		).rejects.toThrow(SlotUnavailableError)
	})

	it('throws SlotUnavailableError when the slot is already booked', async () => {
		bookingStoreMock.listUpcoming.mockResolvedValue([{ slotStart: availableSlotStart }])

		await expect(
			useCase.execute({ name: 'John Doe', email: 'john@example.com', slotStart: availableSlotStart })
		).rejects.toThrow(SlotUnavailableError)
	})

	it('does not call book or sendEmail when validation fails', async () => {
		await expect(useCase.execute({ name: 'John Doe' })).rejects.toThrow()

		expect(bookingStoreMock.book).not.toHaveBeenCalled()
		expect(mailerMock.sendEmail).not.toHaveBeenCalled()
	})

	it('does not call book or sendEmail when the slot is unavailable', async () => {
		await expect(
			useCase.execute({ name: 'John Doe', email: 'john@example.com', slotStart: '2026-03-02T20:00:00.000Z' })
		).rejects.toThrow()

		expect(bookingStoreMock.book).not.toHaveBeenCalled()
		expect(mailerMock.sendEmail).not.toHaveBeenCalled()
	})

	it('stores null for company when not provided', async () => {
		await useCase.execute({ name: 'John Doe', email: 'john@example.com', slotStart: availableSlotStart })

		expect(bookingStoreMock.book).toHaveBeenCalledWith(
			expect.objectContaining({ booking: expect.objectContaining({ company: null }) })
		)
	})

	it('stores the provided company', async () => {
		await useCase.execute({
			name: 'John Doe',
			email: 'john@example.com',
			company: 'Acme Inc',
			slotStart: availableSlotStart,
		})

		expect(bookingStoreMock.book).toHaveBeenCalledWith(
			expect.objectContaining({ booking: expect.objectContaining({ company: 'Acme Inc' }) })
		)
	})
})
