class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create dev_signin ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  def dev_signin
    if Rails.env.development? || Rails.env.test?
      user = User.find_by(email_address: "test@example.com")
      if user
        start_new_session_for user
        redirect_to after_authentication_url, notice: "Signed in as test@example.com (dev mode)"
      else
        redirect_to new_session_path, alert: "Dev user not found. Run 'rails db:seed' to create it."
      end
    else
      redirect_to new_session_path
    end
  end
end
