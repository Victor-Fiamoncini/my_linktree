module SeoHelper
  def default_title
    t("layouts.application.title_fallback", author: SeoConfig::AUTHOR_NAME, job_title: t("seo.job_title"))
  end

  def default_description
    t("seo.default_description", xp_years: GetXpYearsUseCase.new.execute)
  end

  def canonical_path
    content_for(:canonical) || request.path
  end
end
