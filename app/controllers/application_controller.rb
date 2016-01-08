class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user
    @current_user ||= User.find_by auth_token: request.headers['Authorization']
  end

  def current_user?(user)
    user == current_user
  end

  def logged_in?
    !current_user.nil?
  end

  private
    
    def  logged_in_user
      render json: {errors: "Not authenticated" },
             status: :unauthorized unless logged_in?
    end

    def correct_user
      @user ||= User.find_by id: params[:id]
      render json: { errors: "Invalid user" },
             status: 403 unless !@user.nil? && current_user?(@user)
    end
end
