import { describe, it, expect, vi, beforeEach } from 'vitest'

const mockZrange = vi.hoisted(() => vi.fn())
const mockZadd = vi.hoisted(() => vi.fn())

vi.mock('@upstash/redis', () => ({
	Redis: class {
		constructor() {
			this.zrange = mockZrange
			this.zadd = mockZadd
		}
	},
}))

import { UpstashBookingStore } from '@/core/infrastructure/scheduling/upstash-booking-store'

describe('UpstashBookingStore', () => {
	let bookingStore

	beforeEach(() => {
		mockZrange.mockReset()
		mockZadd.mockReset()
		bookingStore = new UpstashBookingStore()
	})

	describe('listUpcoming()', () => {
		it('returns the bookings within the given score range', async () => {
			const bookings = [{ name: 'John Doe', email: 'john@example.com', slotStart: '2026-01-05T12:00:00.000Z' }]
			mockZrange.mockResolvedValue(bookings)

			const result = await bookingStore.listUpcoming({ fromEpochMs: 0, toEpochMs: 1000 })

			expect(result).toEqual(bookings)
		})

		it('calls zrange with the key, range and byScore option', async () => {
			mockZrange.mockResolvedValue([])

			await bookingStore.listUpcoming({ fromEpochMs: 100, toEpochMs: 200 })

			expect(mockZrange).toHaveBeenCalledWith('scheduling:bookings', 100, 200, { byScore: true })
		})
	})

	describe('book()', () => {
		it('calls zadd with the key, score and booking as member', async () => {
			const booking = { name: 'John Doe', email: 'john@example.com', slotStart: '2026-01-05T12:00:00.000Z' }

			await bookingStore.book({ slotStartEpochMs: 1767614400000, booking })

			expect(mockZadd).toHaveBeenCalledWith('scheduling:bookings', { score: 1767614400000, member: booking })
		})
	})
})
