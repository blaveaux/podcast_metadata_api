class V1::PodcastsController < ApplicationController
  before_action :logged_in_user,  only: [:create, :update, :destroy]
  before_action :correct_user,    only: [:create, :update, :destroy]
  before_action :correct_podcast, only: [:update, :destroy]

  def show
    @podcast = Podcast.find_by id: params[:id]
    render json: { errors: "Invalid podcast" }, status: 403 and return unless @podcast

    render json: @podcast
  end

  def index
    @podcasts = Podcast.all
    render json: @podcasts
  end

  def create
    @podcast = @user.podcasts.build(podcast_params)
    if @podcast.save
      render json: @podcast, status: 201
    else
      render json: { errors: @podcast.errors }, status: 422
    end
  end

  def update
    if @podcast.update(podcast_params)
      render json: @podcast, status: 200
    else
      render json: { errors: @podcast.errors }, status: 422
    end
  end

  def destroy
    @podcast.destroy
    head 204
  end

  private

    def podcast_params
      params.require(:podcast).permit(:title, :podcast_file, :remote_podcast_file_url)
    end

    #TODO: refactor with nearly duplicate users_controller.correct_user
    def correct_user
      @user ||= User.find_by id: params[:user_id]
      render json: { errors: "Invalid user" },
             status: 403 unless !@user.nil? && current_user?(@user)
    end

    def correct_podcast
      @podcast ||= @user.podcasts.find_by id: params[:id]
      render json: { errors: "Invalid podcast" }, status: 403 unless @podcast
    end
end
