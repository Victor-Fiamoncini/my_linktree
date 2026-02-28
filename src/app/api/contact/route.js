import {
	MissingRequiredFieldsError,
	SendContactEmailUseCase,
} from '@/core/application/use-cases/send-contact-email-use-case'
import { InternalServerError } from '@/core/infrastructure/errors'
import { ResendMailer } from '@/core/infrastructure/mailer/resend-mailer'

export async function POST(request) {
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
