module UseCases
  class GetXpYearsUseCase
    START_YEAR_OF_WORK = 2019

    def start_year_of_work
      START_YEAR_OF_WORK
    end

    def execute
      Time.current.year - START_YEAR_OF_WORK
    end
  end
end
