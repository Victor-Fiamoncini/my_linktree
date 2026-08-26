import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import { RecordAgentConnectionUseCase } from '@/core/application/use-cases/record-agent-connection-use-case'

describe('RecordAgentConnectionUseCase', () => {
	let connectionLogMock
	let useCase

	beforeEach(() => {
		vi.useFakeTimers()
		vi.setSystemTime(new Date('2026-03-02T12:00:00.000Z'))

		connectionLogMock = {
			record: vi.fn(),
		}

		useCase = new RecordAgentConnectionUseCase({ connectionLog: connectionLogMock })
	})

	afterEach(() => {
		vi.useRealTimers()
	})

	it('records the tool name with the current timestamp', async () => {
		await useCase.execute({ tool: 'get_resume' })

		expect(connectionLogMock.record).toHaveBeenCalledWith({
			tool: 'get_resume',
			timestamp: '2026-03-02T12:00:00.000Z',
		})
	})

	it('propagates errors thrown by the connection log', async () => {
		connectionLogMock.record.mockRejectedValue(new Error('Redis failure'))

		await expect(useCase.execute({ tool: 'get_resume' })).rejects.toThrow('Redis failure')
	})
})
