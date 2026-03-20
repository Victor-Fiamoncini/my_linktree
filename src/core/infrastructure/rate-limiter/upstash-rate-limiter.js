import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

export class UpstashRateLimiter {
	#limiter

	constructor({ maxRequests, window }) {
		this.#limiter = new Ratelimit({
			redis: new Redis({
				url: process.env.STORAGE_KV_REST_API_URL,
				token: process.env.STORAGE_KV_REST_API_TOKEN,
			}),
			limiter: Ratelimit.slidingWindow(maxRequests, window),
		})
	}

	async isAllowed(identifier) {
		const { success } = await this.#limiter.limit(identifier)
		return success
	}
}
