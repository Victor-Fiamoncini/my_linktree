import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import { CheckAvailabilityUseCase } from '@/core/application/use-cases/check-availability-use-case'
import { availabilityConfig as realAvailabilityConfig } from '@/core/infrastructure/scheduling/availability-config'

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

	it('generates slots from multiple non-overlapping windows on the same day', async () => {
		useCase = new CheckAvailabilityUseCase({
			bookingStore: bookingStoreMock,
			availabilityConfig: {
				timezone: 'America/Sao_Paulo',
				slotDurationMinutes: 30,
				weeklyWindows: [
					{ weekday: 1, start: '09:00', end: '10:00' },
					{ weekday: 1, start: '14:00', end: '15:00' },
				],
				bookingHorizonDays: 1,
			},
		})

		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T08:00:00.000Z')) // Monday, 05:00 BRT

		const result = await useCase.execute()

		expect(result.slots).toEqual([
			'2026-03-02T12:00:00.000Z',
			'2026-03-02T12:30:00.000Z',
			'2026-03-02T17:00:00.000Z',
			'2026-03-02T17:30:00.000Z',
		])
	})

	it('drops the remainder of a window that does not divide evenly into slotDurationMinutes', async () => {
		useCase = new CheckAvailabilityUseCase({
			bookingStore: bookingStoreMock,
			availabilityConfig: {
				timezone: 'America/Sao_Paulo',
				slotDurationMinutes: 30,
				weeklyWindows: [{ weekday: 1, start: '09:00', end: '09:45' }],
				bookingHorizonDays: 1,
			},
		})

		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T08:00:00.000Z')) // Monday, 05:00 BRT

		const result = await useCase.execute()

		expect(result.slots).toEqual(['2026-03-02T12:00:00.000Z'])
	})

	it('excludes a slot that starts exactly at "now"', async () => {
		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T12:00:00.000Z'))

		const result = await useCase.execute()

		expect(result.slots).toEqual(['2026-03-02T12:30:00.000Z', '2026-03-03T12:00:00.000Z', '2026-03-03T12:30:00.000Z'])
	})

	it('returns no slots for weekdays with no configured window', async () => {
		useCase = new CheckAvailabilityUseCase({
			bookingStore: bookingStoreMock,
			availabilityConfig: {
				timezone: 'America/Sao_Paulo',
				slotDurationMinutes: 30,
				weeklyWindows: [1, 2, 3, 4, 5].map(weekday => ({ weekday, start: '09:00', end: '10:00' })),
				bookingHorizonDays: 3,
			},
		})

		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-06T08:00:00.000Z')) // Friday, 05:00 BRT; horizon covers Fri, Sat, Sun

		const result = await useCase.execute()

		expect(result.slots).toEqual(['2026-03-06T12:00:00.000Z', '2026-03-06T12:30:00.000Z'])
	})

	it('applies the correct UTC offset on each side of a DST transition', async () => {
		useCase = new CheckAvailabilityUseCase({
			bookingStore: bookingStoreMock,
			availabilityConfig: {
				timezone: 'America/New_York',
				slotDurationMinutes: 60,
				weeklyWindows: [0, 1, 2, 3, 4, 5, 6].map(weekday => ({ weekday, start: '09:00', end: '10:00' })),
				bookingHorizonDays: 3,
			},
		})

		// US DST begins 2026-03-08: EST (UTC-5) before, EDT (UTC-4) on and after.
		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-07T06:00:00.000Z')) // 01:00 EST, still March 7 in New York

		const result = await useCase.execute()

		expect(result.slots).toEqual([
			'2026-03-07T14:00:00.000Z', // 09:00 EST (UTC-5)
			'2026-03-08T13:00:00.000Z', // 09:00 EDT (UTC-4)
			'2026-03-09T13:00:00.000Z', // 09:00 EDT (UTC-4)
		])
	})

	it('works end-to-end with the real availabilityConfig', async () => {
		useCase = new CheckAvailabilityUseCase({
			bookingStore: bookingStoreMock,
			availabilityConfig: realAvailabilityConfig,
		})

		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T03:00:00.000Z')) // Monday, 00:00 BRT

		const result = await useCase.execute()

		const daySlots = date => result.slots.filter(slot => slot.startsWith(date))

		expect(daySlots('2026-03-02')).toHaveLength(18) // Monday: 09:00-18:00 in 30-min slots
		expect(daySlots('2026-03-07')).toHaveLength(0) // Saturday: no configured window
		expect(daySlots('2026-03-08')).toHaveLength(0) // Sunday: no configured window
		expect(result.slots[0]).toBe('2026-03-02T12:00:00.000Z')
	})
})
