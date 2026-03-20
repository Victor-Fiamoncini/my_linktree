import {
	MissingRequiredFieldsError,
	SendContactEmailUseCase,
} from '@/core/application/use-cases/send-contact-email-use-case'
import { InternalServerError, TooManyRequestsError } from '@/core/infrastructure/errors'
import { ResendMailer } from '@/core/infrastructure/mailer/resend-mailer'
import { UpstashRateLimiter } from '@/core/infrastructure/rate-limiter/upstash-rate-limiter'

const rateLimiter = new UpstashRateLimiter({ maxRequests: 2, window: '10 m' })

export async function POST(request) {
	const ip = request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip')

	if (ip && !(await rateLimiter.isAllowed(ip))) {
		return Response.json(new TooManyRequestsError(), { status: 429 })
	}

	const { name, email, message } = await request.json()

	try {
		const sendContactEmailUseCase = new SendContactEmailUseCase({
			mailer: new ResendMailer({ resendApiKey: process.env.RESEND_API_KEY }),
			senderEmail: process.env.SENDER_EMAIL,
			recipientEmail: process.env.RECIPIENT_EMAIL,
		})

		await sendContactEmailUseCase.execute({ name, email, message })

		return new Response(null, { status: 204 })
	} catch (error) {
		if (error instanceof MissingRequiredFieldsError) {
			return Response.json(error, { status: 400 })
		}

		const internalServerError = new InternalServerError({ cause: error })

		console.error(internalServerError)

		return Response.json(internalServerError, { status: 500 })
	}
}
