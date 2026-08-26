export class ListRecentConnectionsUseCase {
	#connectionLog

	constructor({ connectionLog }) {
		this.#connectionLog = connectionLog
	}

	async execute() {
		return await this.#connectionLog.listRecent()
	}
}
