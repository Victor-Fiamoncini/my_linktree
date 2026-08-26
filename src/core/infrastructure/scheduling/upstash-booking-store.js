import { Redis } from '@upstash/redis'

const RESERVATION_TTL_SECONDS = 60 * 60 * 24 * 90

export class UpstashBookingStore {
	#redis
	#key = 'scheduling:bookings'
	#reservationKeyPrefix = 'scheduling:reservation:'

	constructor() {
		this.#redis = new Redis({
			url: process.env.STORAGE_KV_REST_API_URL,
			token: process.env.STORAGE_KV_REST_API_TOKEN,
		})
	}

	async listUpcoming({ fromEpochMs, toEpochMs }) {
		return await this.#redis.zrange(this.#key, fromEpochMs, toEpochMs, { byScore: true })
	}

	async book({ slotStartEpochMs, booking }) {
		const reserved = await this.#redis.set(`${this.#reservationKeyPrefix}${slotStartEpochMs}`, booking, {
			nx: true,
			ex: RESERVATION_TTL_SECONDS,
		})

		if (!reserved) {
			return false
		}

		await this.#redis.zadd(this.#key, { score: slotStartEpochMs, member: booking })

		return true
	}
}
