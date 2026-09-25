class PagesController < ApplicationController
  def root_redirect
    locale = detected_locale

    response.set_header("Cache-Control", "private, no-store")

    redirect_to "/#{locale}#{query_suffix}", status: :found
  end

  def home
    @profile = GetProfileUseCase.new.execute
    @services = ListServicesUseCase.new.execute

    xp_years_use_case = GetXpYearsUseCase.new
    @xp_years = xp_years_use_case.execute
    @start_year_of_work = xp_years_use_case.start_year_of_work
  end

  private

  def query_suffix
    query_string = request.query_string.presence

    query_string ? "?#{query_string}" : ""
  end
end
