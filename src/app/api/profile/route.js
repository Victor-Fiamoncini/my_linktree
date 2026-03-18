import { InternalServerError } from '@/core/infrastructure/errors'
import { GetProfileUseCase } from '@/core/application/use-cases/get-profile-use-case'
import { MemoryDatabase } from '@/core/infrastructure/database/memory-database'

export async function GET() {
	try {
		const getProfileUseCase = new GetProfileUseCase({ database: new MemoryDatabase() })

		return new Response(await getProfileUseCase.execute(), { status: 200 })
	} catch (error) {
		const internalServerError = new InternalServerError({ cause: error })

		console.error(internalServerError)

		return Response.json(internalServerError, { status: 500 })
	}
}
