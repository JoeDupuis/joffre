class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    user = find_user_for_authentication

    if user
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: authentication_error_message
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "You have been logged out successfully."
  end

  private

  def find_user_for_authentication
    return dev_user_authentication if Rails.env.development? && params[:dev_user_email].present?

    User.authenticate_by(params.permit(:email_address, :password))
  end

  def dev_user_authentication
    User.find_by(email_address: params[:dev_user_email])
  end

  def authentication_error_message
    return "Dev user not found." if Rails.env.development? && params[:dev_user_email].present?

    "Try another email address or password."
  end
end
