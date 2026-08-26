import { describe, it, expect, beforeEach, vi } from 'vitest'

// Fake sorted set backed by an in-memory array so the real UpstashBookingStore
// class is exercised without a real Redis connection.
class FakeSortedSet {
	#store = new Map()

	zadd(key, { score, member }) {
		const entries = this.#store.get(key) ?? []
		entries.push({ score, member })
		this.#store.set(key, entries)
		return Promise.resolve(1)
	}

	zrange(key, min, max) {
		const entries = this.#store.get(key) ?? []
		return Promise.resolve(
			entries
				.filter(entry => entry.score >= min && entry.score <= max)
				.sort((a, b) => a.score - b.score)
				.map(entry => entry.member)
		)
	}
}

let fakeSortedSet

vi.mock('@upstash/redis', () => ({
	Redis: class {
		constructor() {
			this.zadd = (...args) => fakeSortedSet.zadd(...args)
			this.zrange = (...args) => fakeSortedSet.zrange(...args)
		}
	},
}))

import { UpstashBookingStore } from '@/core/infrastructure/scheduling/upstash-booking-store'

describe('UpstashBookingStore integration', () => {
	let bookingStore

	beforeEach(() => {
		fakeSortedSet = new FakeSortedSet()
		bookingStore = new UpstashBookingStore()
	})

	it('returns an empty list when there are no bookings in range', async () => {
		const result = await bookingStore.listUpcoming({ fromEpochMs: 0, toEpochMs: Date.now() })

		expect(result).toEqual([])
	})

	it('returns a booked slot within the requested range', async () => {
		const booking = { name: 'John Doe', email: 'john@example.com', slotStart: '2026-03-02T12:00:00.000Z' }
		const slotStartEpochMs = new Date(booking.slotStart).getTime()

		await bookingStore.book({ slotStartEpochMs, booking })

		const result = await bookingStore.listUpcoming({
			fromEpochMs: slotStartEpochMs - 1000,
			toEpochMs: slotStartEpochMs + 1000,
		})

		expect(result).toEqual([booking])
	})

	it('excludes bookings outside the requested range', async () => {
		const booking = { name: 'Jane Doe', email: 'jane@example.com', slotStart: '2026-03-03T12:00:00.000Z' }
		const slotStartEpochMs = new Date(booking.slotStart).getTime()

		await bookingStore.book({ slotStartEpochMs, booking })

		const result = await bookingStore.listUpcoming({
			fromEpochMs: slotStartEpochMs + 1000,
			toEpochMs: slotStartEpochMs + 2000,
		})

		expect(result).toEqual([])
	})

	it('returns multiple bookings ordered by slot start', async () => {
		const earlier = { name: 'A', email: 'a@example.com', slotStart: '2026-03-04T09:00:00.000Z' }
		const later = { name: 'B', email: 'b@example.com', slotStart: '2026-03-04T14:00:00.000Z' }

		await bookingStore.book({ slotStartEpochMs: new Date(later.slotStart).getTime(), booking: later })
		await bookingStore.book({ slotStartEpochMs: new Date(earlier.slotStart).getTime(), booking: earlier })

		const result = await bookingStore.listUpcoming({
			fromEpochMs: new Date(earlier.slotStart).getTime(),
			toEpochMs: new Date(later.slotStart).getTime(),
		})

		expect(result).toEqual([earlier, later])
	})
})
