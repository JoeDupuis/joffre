module ApplicationHelper
  def form_errors(instance, **locals)
    locals[:instance] = instance
    render partial: "application/form_errors", locals: locals
  end
end
