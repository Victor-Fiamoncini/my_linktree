export const startYearOfWork = 2019

class GetYearsOfXpUseCase {
	execute(startYear = startYearOfWork) {
		const currentYear = new Date().getFullYear()

		return currentYear - startYear
	}
}

export default GetYearsOfXpUseCase
