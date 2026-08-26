export class ConsoleMailer {
	async sendEmail({ from, to, subject, html }) {
		console.log(`[ConsoleMailer] from=${from} to=${to} subject=${subject}\n${html}`)
	}
}
