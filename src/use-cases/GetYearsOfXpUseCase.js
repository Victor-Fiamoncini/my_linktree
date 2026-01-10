class GetYearsOfXpUseCase {
	#startYearOfWork

	constructor() {
		this.#startYearOfWork = 2019
	}

	get startYearOfWork() {
		return this.#startYearOfWork
	}

	execute() {
		const currentYear = new Date().getFullYear()

		return currentYear - this.#startYearOfWork
	}
}

export default GetYearsOfXpUseCase
