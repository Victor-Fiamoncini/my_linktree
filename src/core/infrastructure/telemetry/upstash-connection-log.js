import { Redis } from '@upstash/redis'

const MAX_ENTRIES = 50
const TTL_SECONDS = 60 * 60 * 24 * 7

export class UpstashConnectionLog {
	#redis
	#key = 'telemetry:connections'

	constructor() {
		this.#redis = new Redis({
			url: process.env.STORAGE_KV_REST_API_URL,
			token: process.env.STORAGE_KV_REST_API_TOKEN,
		})
	}

	async record(entry) {
		await this.#redis.lpush(this.#key, entry)
		await this.#redis.ltrim(this.#key, 0, MAX_ENTRIES - 1)
		await this.#redis.expire(this.#key, TTL_SECONDS)
	}

	async listRecent() {
		return await this.#redis.lrange(this.#key, 0, MAX_ENTRIES - 1)
	}
}
