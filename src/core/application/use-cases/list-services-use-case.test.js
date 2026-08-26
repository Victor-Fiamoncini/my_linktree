import { describe, it, expect, vi, beforeEach } from 'vitest'

import { ListServicesUseCase } from '@/core/application/use-cases/list-services-use-case'

describe('ListServicesUseCase', () => {
	let databaseMock
	let useCase

	beforeEach(() => {
		databaseMock = {
			getServices: vi.fn(),
		}

		useCase = new ListServicesUseCase({ database: databaseMock })
	})

	it('should return the services from the database', async () => {
		const services = [{ id: 1, name: 'Web development', description: 'FE/BE systems' }]

		databaseMock.getServices.mockResolvedValue(services)

		const result = await useCase.execute()

		expect(result).toEqual(services)
	})

	it('should call database.getServices once', async () => {
		databaseMock.getServices.mockResolvedValue([])

		await useCase.execute()

		expect(databaseMock.getServices).toHaveBeenCalledTimes(1)
	})

	it('should propagate errors thrown by the database', async () => {
		databaseMock.getServices.mockRejectedValue(new Error('Database failure'))

		await expect(useCase.execute()).rejects.toThrow('Database failure')
	})
})
