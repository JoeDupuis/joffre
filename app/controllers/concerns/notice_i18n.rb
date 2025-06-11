module NoticeI18n
  extend ActiveSupport::Concern

  private

  def success_message(model = nil)
    i18n_message(:success, model)
  end

  def failure_message(model = nil)
    i18n_message(:failure, model)
  end

  def i18n_message(type, model = nil)
    key = "#{controller_path.tr('/', '.')}.#{action_name}.#{type}"
    default_key = "application.#{action_name}.#{type}"

    options = {
      default: I18n.t(default_key, default: "#{action_name.humanize} #{type}!")
    }

    if model.present?
      options[:name] = model.model_name.human
      options[:model] = model
    end

    I18n.t(key, **options)
  end
end
