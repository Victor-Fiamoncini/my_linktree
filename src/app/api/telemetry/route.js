import { ListRecentConnectionsUseCase } from '@/core/application/use-cases/list-recent-connections-use-case'
import { InternalServerError } from '@/core/infrastructure/errors'
import { UpstashConnectionLog } from '@/core/infrastructure/telemetry/upstash-connection-log'

export async function GET() {
	try {
		const listRecentConnectionsUseCase = new ListRecentConnectionsUseCase({ connectionLog: new UpstashConnectionLog() })

		return Response.json(await listRecentConnectionsUseCase.execute(), { status: 200 })
	} catch (error) {
		const internalServerError = new InternalServerError({ cause: error })

		console.error(internalServerError)

		return Response.json(internalServerError, { status: 500 })
	}
}
