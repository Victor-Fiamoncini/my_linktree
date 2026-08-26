class PagesController < ApplicationController
  def home
    @profile = UseCases::GetProfileUseCase.new.execute
    @services = UseCases::ListServicesUseCase.new.execute

    xp_years_use_case = UseCases::GetXpYearsUseCase.new
    @xp_years = xp_years_use_case.execute
    @start_year_of_work = xp_years_use_case.start_year_of_work
  end
end
