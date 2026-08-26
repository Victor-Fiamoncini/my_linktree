import { describe, it, expect, vi, beforeEach } from 'vitest'

const mockLpush = vi.hoisted(() => vi.fn())
const mockLtrim = vi.hoisted(() => vi.fn())
const mockExpire = vi.hoisted(() => vi.fn())
const mockLrange = vi.hoisted(() => vi.fn())

vi.mock('@upstash/redis', () => ({
	Redis: class {
		constructor() {
			this.lpush = mockLpush
			this.ltrim = mockLtrim
			this.expire = mockExpire
			this.lrange = mockLrange
		}
	},
}))

import { UpstashConnectionLog } from '@/core/infrastructure/telemetry/upstash-connection-log'

describe('UpstashConnectionLog', () => {
	let connectionLog

	beforeEach(() => {
		mockLpush.mockReset().mockResolvedValue(1)
		mockLtrim.mockReset().mockResolvedValue('OK')
		mockExpire.mockReset().mockResolvedValue(1)
		mockLrange.mockReset()

		connectionLog = new UpstashConnectionLog()
	})

	describe('record()', () => {
		it('pushes the entry onto the list', async () => {
			const entry = { tool: 'get_resume', timestamp: '2026-03-02T12:00:00.000Z' }

			await connectionLog.record(entry)

			expect(mockLpush).toHaveBeenCalledWith('telemetry:connections', entry)
		})

		it('trims the list to the max size', async () => {
			await connectionLog.record({ tool: 'get_resume', timestamp: '2026-03-02T12:00:00.000Z' })

			expect(mockLtrim).toHaveBeenCalledWith('telemetry:connections', 0, 49)
		})

		it('refreshes the TTL', async () => {
			await connectionLog.record({ tool: 'get_resume', timestamp: '2026-03-02T12:00:00.000Z' })

			expect(mockExpire).toHaveBeenCalledWith('telemetry:connections', 60 * 60 * 24 * 7)
		})
	})

	describe('listRecent()', () => {
		it('returns the entries from the list', async () => {
			const entries = [{ tool: 'get_resume', timestamp: '2026-03-02T12:00:00.000Z' }]
			mockLrange.mockResolvedValue(entries)

			const result = await connectionLog.listRecent()

			expect(result).toEqual(entries)
		})

		it('calls lrange with the key and max size bounds', async () => {
			mockLrange.mockResolvedValue([])

			await connectionLog.listRecent()

			expect(mockLrange).toHaveBeenCalledWith('telemetry:connections', 0, 49)
		})
	})
})
