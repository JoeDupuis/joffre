class ApplicationController < ActionController::Base
  include Authentication
  include NoticeI18n
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :switch_locale

  private

  def switch_locale(&action)
    I18n.with_locale(requested_locale, &action)
  end

  def requested_locale
    saved_user_locale || accept_language_locale || I18n.default_locale
  end

  def saved_user_locale
    return unless authenticated?

    locale = Current.user.locale
    locale if I18n.locale_available?(locale)
  end

  def accept_language_locale
    accept_language_ranges.find { |language| I18n.locale_available?(language) }
  end

  def accept_language_ranges
    ranges = request.headers["Accept-Language"].to_s.split(",").each_with_index.filter_map do |range, position|
      tag, *parameters = range.split(";").map(&:strip)
      next if tag.blank?

      quality = parameters.find { |parameter| parameter.start_with?("q=") }&.delete_prefix("q=")&.to_f || 1.0
      [ tag.split("-").first.downcase, quality, position ] if quality.positive?
    end

    ranges.sort_by { |_, quality, position| [ -quality, position ] }.map(&:first)
  end
end
