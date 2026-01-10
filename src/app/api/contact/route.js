import {
	MissingRequiredFieldsError,
	SendContactEmailUseCase,
} from '@/core/application/use-cases/send-contact-email-use-case'
import { ResendMailer } from '@/core/infrastructure/resend-mailer'

const sendContactEmailUseCase = new SendContactEmailUseCase({
	mailer: new ResendMailer({ resendApiKey: process.env.RESEND_API_KEY }),
	senderEmail: process.env.SENDER_EMAIL,
	recipientEmail: process.env.RECIPIENT_EMAIL,
})

export async function POST(request, response) {
	try {
		const { name, email, message } = await request.json()

		await sendContactEmailUseCase.execute({ name, email, message })

		return Response.json({ success: true }, { status: 200 })
	} catch (error) {
		if (error instanceof MissingRequiredFieldsError) {
			return Response.json({ success: false, error: error.message }, { status: 400 })
		}

		return Response.json({ success: false, error: 'Something went wrong, try again later' }, { status: 500 })
	}
}
