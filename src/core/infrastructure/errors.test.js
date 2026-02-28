import { describe, it, expect } from 'vitest'

import { InternalServerError } from '@/core/infrastructure/errors'

describe('InternalServerError', () => {
	it('is an instance of Error', () => {
		const error = new InternalServerError({ cause: new Error('original') })

		expect(error).toBeInstanceOf(Error)
	})

	it('has the correct message', () => {
		const error = new InternalServerError({ cause: new Error() })

		expect(error.message).toBe('Internal Server Error')
	})

	it('has the correct name', () => {
		const error = new InternalServerError({ cause: new Error() })

		expect(error.name).toBe('InternalServerError')
	})

	it('has the correct action', () => {
		const error = new InternalServerError({ cause: new Error() })

		expect(error.action).toBe('Please contact the administrator of the application.')
	})

	it('stores the cause', () => {
		const cause = new Error('original error')
		const error = new InternalServerError({ cause })

		expect(error.cause).toBe(cause)
	})

	describe('toJSON()', () => {
		it('returns name, message and action', () => {
			const error = new InternalServerError({ cause: new Error() })

			expect(error.toJSON()).toEqual({
				name: 'InternalServerError',
				message: 'Internal Server Error',
				action: 'Please contact the administrator of the application.',
			})
		})

		it('does not expose cause in the serialized output', () => {
			const error = new InternalServerError({ cause: new Error('secret details') })

			expect(error.toJSON()).not.toHaveProperty('cause')
		})
	})
})
