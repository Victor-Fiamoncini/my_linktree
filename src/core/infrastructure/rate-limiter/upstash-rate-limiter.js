import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

export class UpstashRateLimiter {
	#limiter

	constructor({ maxRequests, window }) {
		this.#limiter = new Ratelimit({
			redis: Redis.fromEnv(),
			limiter: Ratelimit.slidingWindow(maxRequests, window),
		})
	}

	async isAllowed(identifier) {
		const { success } = await this.#limiter.limit(identifier)
		return success
	}
}
