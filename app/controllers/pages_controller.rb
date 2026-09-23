class PagesController < ApplicationController
  def home
    @profile = GetProfileUseCase.new.execute
    @services = ListServicesUseCase.new.execute

    xp_years_use_case = GetXpYearsUseCase.new
    @xp_years = xp_years_use_case.execute
    @start_year_of_work = xp_years_use_case.start_year_of_work
  end
end
