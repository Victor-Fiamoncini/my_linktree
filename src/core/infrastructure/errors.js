export class InternalServerError extends Error {
	constructor({ cause }) {
		super('Internal Server Error', { cause })

		this.name = 'InternalServerError'
		this.action = 'Please contact the administrator of the application.'
	}

	toJSON() {
		return {
			name: this.name,
			message: this.message,
			action: this.action,
		}
	}
}
