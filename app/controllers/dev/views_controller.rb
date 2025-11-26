class Dev::ViewsController < ApplicationController
  before_action :ensure_development_environment
  before_action :set_flash_messages
  allow_unauthenticated_access

  def index
    @views = Dir.glob(Rails.root.join("app/views/dev/views/*.html.erb"))
      .map { |f| File.basename(f, ".html.erb") }
      .reject { |f| f.start_with?("_") || f == "index" }
      .sort
  end

  def show
    render params[:name]
  end

  private

  def ensure_development_environment
    head :forbidden unless Rails.env.development?
  end

  def set_flash_messages
    flash.now[:notice] = params[:flash_notice] if params[:flash_notice]
    flash.now[:alert] = params[:flash_alert] if params[:flash_alert]
  end
end
