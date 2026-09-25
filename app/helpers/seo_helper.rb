module SeoHelper
  def default_description
    t("seo.default_description", xp_years: GetXpYearsUseCase.new.execute)
  end
end
