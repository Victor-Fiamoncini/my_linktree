export class GetProfileUseCase {
	#database

	constructor({ database }) {
		this.#database = database
	}

	async execute() {
		return await this.#database.getProfile()
	}
}
