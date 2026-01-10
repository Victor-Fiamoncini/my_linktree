import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function POST(request, response) {
	try {
		const { name, email, message } = await request.json()

		if (!name || !email || !message) {
			return Response.json({ success: false, error: 'Missing required fields' }, { status: 400 })
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

		return Response.json({ success: true }, { status: 200 })
	} catch {
		return Response.json({ success: false, error: 'Something went wrong, try again later' }, { status: 500 })
	}
}
