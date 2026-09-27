class LocalesController < ApplicationController
  def update
    if Current.user.update(locale: params[:locale].to_s)
      redirect_back_or_to root_path
    else
      redirect_back_or_to root_path, alert: failure_message
    end
  end
end
