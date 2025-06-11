class DashboardController < ApplicationController
  def index
    @games = Current.user.games.includes(:players, :users)
  end
end
