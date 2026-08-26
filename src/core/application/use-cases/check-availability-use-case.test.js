import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import { CheckAvailabilityUseCase } from '@/core/application/use-cases/check-availability-use-case'

const availabilityConfig = {
	timezone: 'America/Sao_Paulo',
	slotDurationMinutes: 30,
	weeklyWindows: [0, 1, 2, 3, 4, 5, 6].map(weekday => ({ weekday, start: '09:00', end: '10:00' })),
	bookingHorizonDays: 2,
}

describe('CheckAvailabilityUseCase', () => {
	let bookingStoreMock
	let useCase

	beforeEach(() => {
		bookingStoreMock = {
			listUpcoming: vi.fn().mockResolvedValue([]),
		}

		useCase = new CheckAvailabilityUseCase({ bookingStore: bookingStoreMock, availabilityConfig })
	})

	afterEach(() => {
		vi.useRealTimers()
	})

	it('returns the configured timezone', async () => {
		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T08:00:00.000Z'))

		const result = await useCase.execute()

		expect(result.timezone).toBe('America/Sao_Paulo')
	})

	it('returns all free slots for the configured horizon and windows', async () => {
		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T08:00:00.000Z'))

		const result = await useCase.execute()

		expect(result.slots).toEqual([
			'2026-03-02T12:00:00.000Z',
			'2026-03-02T12:30:00.000Z',
			'2026-03-03T12:00:00.000Z',
			'2026-03-03T12:30:00.000Z',
		])
	})

	it('excludes slots that already started', async () => {
		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T12:15:00.000Z'))

		const result = await useCase.execute()

		expect(result.slots).toEqual(['2026-03-02T12:30:00.000Z', '2026-03-03T12:00:00.000Z', '2026-03-03T12:30:00.000Z'])
	})

	it('excludes slots that are already booked', async () => {
		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T08:00:00.000Z'))

		bookingStoreMock.listUpcoming.mockResolvedValue([{ slotStart: '2026-03-02T12:00:00.000Z' }])

		const result = await useCase.execute()

		expect(result.slots).not.toContain('2026-03-02T12:00:00.000Z')
		expect(result.slots).toEqual(['2026-03-02T12:30:00.000Z', '2026-03-03T12:00:00.000Z', '2026-03-03T12:30:00.000Z'])
	})

	it('queries the booking store for the current-to-horizon range', async () => {
		const now = new Date('2026-03-02T08:00:00.000Z')
		vi.useFakeTimers()
		vi.setSystemTime(now)

		await useCase.execute()

		expect(bookingStoreMock.listUpcoming).toHaveBeenCalledWith({
			fromEpochMs: now.getTime(),
			toEpochMs: expect.any(Number),
		})

		const { toEpochMs } = bookingStoreMock.listUpcoming.mock.calls[0][0]
		expect(toEpochMs).toBeGreaterThan(now.getTime())
	})
})
