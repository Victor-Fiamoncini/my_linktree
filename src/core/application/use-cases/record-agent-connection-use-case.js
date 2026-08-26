export class RecordAgentConnectionUseCase {
	#connectionLog

	constructor({ connectionLog }) {
		this.#connectionLog = connectionLog
	}

	async execute({ tool }) {
		await this.#connectionLog.record({ tool, timestamp: new Date().toISOString() })
	}
}
