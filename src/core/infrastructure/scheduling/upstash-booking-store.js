import { Redis } from '@upstash/redis'

export class UpstashBookingStore {
	#redis
	#key = 'scheduling:bookings'

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
		await this.#redis.zadd(this.#key, { score: slotStartEpochMs, member: booking })
	}
}
