import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request, response) {
	try {
		const { name, email, message } = await request.json()

		if (!name || !email || !message) {
			return response.status(400).json({ success: false, error: 'Missing required fields' })
		}

		await resend.emails.send({
			from: 'mylinktree@victorfiamon.com.br',
			to: process.env.RECIPIENT_EMAIL,
			subject: `My Linktree - New contact from ${name}`,
			html: `
        <p>Name: ${name}</p>
        <p>Email: ${email}</p>
        <p>Message: ${message}</p>
      `,
		})

		return response.status(200).json({ success: true })
	} catch {
		return response.status(500).json({ success: false, error: 'Something went wrong, try again later' })
	}
}
