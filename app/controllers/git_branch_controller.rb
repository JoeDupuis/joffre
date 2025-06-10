class GitBranchController < ApplicationController
  def current
    branch = if Rails.env.development?
      `git rev-parse --abbrev-ref HEAD`.strip
    else
      nil
    end
    
    render json: { branch: branch }
  end
end