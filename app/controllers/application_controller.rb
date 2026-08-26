class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_default_description

  private

  def set_default_description
    xp_years = UseCases::GetXpYearsUseCase.new.execute
    @default_description =
      "Software Engineer with #{xp_years} years of experience in both companies and freelance projects. " \
      "Currently focused on back-end development using PHP (Laravel/Symfony) and NodeJS, while also " \
      "building personal projects with Ruby on Rails and Next.js."
  end
end
