class PagesController < ApplicationController
  def home
    @profile = UseCases::GetProfileUseCase.new.execute
    @services = UseCases::ListServicesUseCase.new.execute
    @xp_years = UseCases::GetXpYearsUseCase.new.execute
  end
end
