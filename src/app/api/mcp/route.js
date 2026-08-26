import { createMcpHandler } from 'mcp-handler'
import { z } from 'zod'

import { GetProfileUseCase } from '@/core/application/use-cases/get-profile-use-case'
import { ListServicesUseCase } from '@/core/application/use-cases/list-services-use-case'
import { CheckAvailabilityUseCase } from '@/core/application/use-cases/check-availability-use-case'
import { ScheduleMeetingUseCase } from '@/core/application/use-cases/schedule-meeting-use-case'
import { RecordAgentConnectionUseCase } from '@/core/application/use-cases/record-agent-connection-use-case'
import { MemoryDatabase } from '@/core/infrastructure/database/memory-database'
import { UpstashBookingStore } from '@/core/infrastructure/scheduling/upstash-booking-store'
import { availabilityConfig } from '@/core/infrastructure/scheduling/availability-config'
import { UpstashConnectionLog } from '@/core/infrastructure/telemetry/upstash-connection-log'
import { createMailer } from '@/core/infrastructure/mailer/create-mailer'
import { UpstashRateLimiter } from '@/core/infrastructure/rate-limiter/upstash-rate-limiter'
import { TooManyRequestsError } from '@/core/infrastructure/errors'

const database = new MemoryDatabase()
const bookingStore = new UpstashBookingStore()
const connectionLog = new UpstashConnectionLog()
const recordAgentConnectionUseCase = new RecordAgentConnectionUseCase({ connectionLog })

const generalRateLimiter = new UpstashRateLimiter({ maxRequests: 30, window: '1 m' })
const scheduleRateLimiter = new UpstashRateLimiter({ maxRequests: 3, window: '10 m' })

const handler = createMcpHandler(server => {
	server.registerTool(
		'get_resume',
		{
			title: 'Get Resume',
			description: "Returns Victor Fiamoncini's resume/CV as structured JSON.",
			inputSchema: z.object({}),
		},
		async () => {
			await recordAgentConnectionUseCase.execute({ tool: 'get_resume' })

			const profile = await new GetProfileUseCase({ database }).execute()

			return { content: [{ type: 'text', text: JSON.stringify(profile) }] }
		}
	)

	server.registerTool(
		'list_services',
		{
			title: 'List Services',
			description: 'Lists the services Victor offers.',
			inputSchema: z.object({}),
		},
		async () => {
			await recordAgentConnectionUseCase.execute({ tool: 'list_services' })

			const services = await new ListServicesUseCase({ database }).execute()

			return { content: [{ type: 'text', text: JSON.stringify(services) }] }
		}
	)

	server.registerTool(
		'check_availability',
		{
			title: 'Check Availability',
			description: 'Lists open meeting slots with Victor.',
			inputSchema: z.object({}),
		},
		async () => {
			await recordAgentConnectionUseCase.execute({ tool: 'check_availability' })

			const availability = await new CheckAvailabilityUseCase({ bookingStore, availabilityConfig }).execute()

			return { content: [{ type: 'text', text: JSON.stringify(availability) }] }
		}
	)

	server.registerTool(
		'schedule_meeting',
		{
			title: 'Schedule Meeting',
			description: 'Books a meeting slot with Victor. Use check_availability first to get a valid slotStart.',
			inputSchema: z.object({
				name: z.string(),
				email: z.string(),
				company: z.string().optional(),
				slotStart: z.string(),
			}),
		},
		async args => {
			await recordAgentConnectionUseCase.execute({ tool: 'schedule_meeting' })

			const scheduleMeetingUseCase = new ScheduleMeetingUseCase({
				bookingStore,
				availabilityConfig,
				mailer: createMailer(),
				senderEmail: process.env.MAILER_SENDER_EMAIL,
				recipientEmail: process.env.MAILER_RECIPIENT_EMAIL,
			})

			const booking = await scheduleMeetingUseCase.execute(args)

			return { content: [{ type: 'text', text: JSON.stringify(booking) }] }
		}
	)
})

async function isScheduleMeetingCall(request) {
	try {
		const body = await request.clone().json()

		return body?.method === 'tools/call' && body?.params?.name === 'schedule_meeting'
	} catch {
		return false
	}
}

export async function POST(request) {
	const ip = request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip')

	if (ip && !(await generalRateLimiter.isAllowed(ip))) {
		return Response.json(new TooManyRequestsError(), { status: 429 })
	}

	if (ip && (await isScheduleMeetingCall(request)) && !(await scheduleRateLimiter.isAllowed(ip))) {
		return Response.json(new TooManyRequestsError(), { status: 429 })
	}

	return handler(request)
}

export { handler as GET }
