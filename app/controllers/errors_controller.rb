# Rendered by config.exceptions_app for 404s only; ShowExceptions rewrites the path to /404.
class ErrorsController < ApplicationController
  LOCALE_PREFIX = %r{\A/(en|pt-BR)(?=/|\z)}

  def not_found
    return render(json: { message: "Not Found" }, status: :not_found) if original_path.match?(%r{\A/api(?:[/.]|\z)})

    @localized_path = original_path.match?(LOCALE_PREFIX) ? original_path : "/#{I18n.locale}#{original_path}"
    response.set_header("Cache-Control", "private, no-store")

    render :not_found, status: :not_found, formats: :html
  end

  private

  # request.path is the rewritten /404 here; log the URL that actually missed.
  def set_event_context
    super
    Rails.event.set_context(path: original_path)
  end

  def switch_locale(&action)
    I18n.with_locale(original_path[LOCALE_PREFIX, 1] || detected_locale, &action)
  end

  def original_path
    request.get_header("action_dispatch.original_path") || request.path
  end
end
