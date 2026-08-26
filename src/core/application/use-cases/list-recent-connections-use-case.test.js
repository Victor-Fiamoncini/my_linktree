import { describe, it, expect, vi, beforeEach } from 'vitest'

import { ListRecentConnectionsUseCase } from '@/core/application/use-cases/list-recent-connections-use-case'

describe('ListRecentConnectionsUseCase', () => {
	let connectionLogMock
	let useCase

	beforeEach(() => {
		connectionLogMock = {
			listRecent: vi.fn(),
		}

		useCase = new ListRecentConnectionsUseCase({ connectionLog: connectionLogMock })
	})

	it('should return the recent connections from the connection log', async () => {
		const connections = [{ tool: 'get_resume', timestamp: '2026-03-02T12:00:00.000Z' }]

		connectionLogMock.listRecent.mockResolvedValue(connections)

		const result = await useCase.execute()

		expect(result).toEqual(connections)
	})

	it('should call connectionLog.listRecent once', async () => {
		connectionLogMock.listRecent.mockResolvedValue([])

		await useCase.execute()

		expect(connectionLogMock.listRecent).toHaveBeenCalledTimes(1)
	})

	it('should propagate errors thrown by the connection log', async () => {
		connectionLogMock.listRecent.mockRejectedValue(new Error('Redis failure'))

		await expect(useCase.execute()).rejects.toThrow('Redis failure')
	})
})
