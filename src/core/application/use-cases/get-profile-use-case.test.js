import { describe, it, expect, vi, beforeEach } from 'vitest'

import { GetProfileUseCase } from '@/core/application/use-cases/get-profile-use-case'

describe('GetProfileUseCase', () => {
	let databaseMock
	let useCase

	beforeEach(() => {
		databaseMock = {
			getProfile: vi.fn(),
		}

		useCase = new GetProfileUseCase({ database: databaseMock })
	})

	it('should return the profile from the database', async () => {
		const profile = { name: 'John Doe', headline: 'Software Engineer' }

		databaseMock.getProfile.mockResolvedValue(profile)

		const result = await useCase.execute()

		expect(result).toEqual(profile)
	})

	it('should call database.getProfile once', async () => {
		databaseMock.getProfile.mockResolvedValue({})

		await useCase.execute()

		expect(databaseMock.getProfile).toHaveBeenCalledTimes(1)
	})

	it('should propagate errors thrown by the database', async () => {
		databaseMock.getProfile.mockRejectedValue(new Error('Database failure'))

		await expect(useCase.execute()).rejects.toThrow('Database failure')
	})
})
