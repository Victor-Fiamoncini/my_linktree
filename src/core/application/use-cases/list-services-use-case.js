export class ListServicesUseCase {
	#database

	constructor({ database }) {
		this.#database = database
	}

	async execute() {
		return await this.#database.getServices()
	}
}
