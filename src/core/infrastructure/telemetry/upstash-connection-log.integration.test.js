import { describe, it, expect, beforeEach, vi } from 'vitest'

// Fake list backed by an in-memory array so the real UpstashConnectionLog
// class is exercised without a real Redis connection.
class FakeList {
	#store = new Map()
	#ttl = new Map()

	lpush(key, entry) {
		const entries = this.#store.get(key) ?? []
		entries.unshift(entry)
		this.#store.set(key, entries)
		return Promise.resolve(entries.length)
	}

	ltrim(key, start, end) {
		const entries = this.#store.get(key) ?? []
		this.#store.set(key, entries.slice(start, end + 1))
		return Promise.resolve('OK')
	}

	expire(key, seconds) {
		this.#ttl.set(key, seconds)
		return Promise.resolve(1)
	}

	lrange(key, start, end) {
		const entries = this.#store.get(key) ?? []
		return Promise.resolve(entries.slice(start, end + 1))
	}
}

let fakeList

vi.mock('@upstash/redis', () => ({
	Redis: class {
		constructor() {
			this.lpush = (...args) => fakeList.lpush(...args)
			this.ltrim = (...args) => fakeList.ltrim(...args)
			this.expire = (...args) => fakeList.expire(...args)
			this.lrange = (...args) => fakeList.lrange(...args)
		}
	},
}))

import { UpstashConnectionLog } from '@/core/infrastructure/telemetry/upstash-connection-log'

describe('UpstashConnectionLog integration', () => {
	let connectionLog

	beforeEach(() => {
		fakeList = new FakeList()
		connectionLog = new UpstashConnectionLog()
	})

	it('returns an empty list when nothing was recorded', async () => {
		expect(await connectionLog.listRecent()).toEqual([])
	})

	it('returns recorded entries newest-first', async () => {
		await connectionLog.record({ tool: 'get_resume', timestamp: '2026-03-02T12:00:00.000Z' })
		await connectionLog.record({ tool: 'list_services', timestamp: '2026-03-02T12:01:00.000Z' })

		expect(await connectionLog.listRecent()).toEqual([
			{ tool: 'list_services', timestamp: '2026-03-02T12:01:00.000Z' },
			{ tool: 'get_resume', timestamp: '2026-03-02T12:00:00.000Z' },
		])
	})

	it('caps the list at 50 entries', async () => {
		for (let i = 0; i < 60; i++) {
			await connectionLog.record({ tool: 'get_resume', timestamp: `entry-${i}` })
		}

		const result = await connectionLog.listRecent()

		expect(result).toHaveLength(50)
		expect(result[0]).toEqual({ tool: 'get_resume', timestamp: 'entry-59' })
	})
})
