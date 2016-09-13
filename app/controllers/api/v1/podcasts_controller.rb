class Api::V1::PodcastsController < Api::V1::PublishableController
  prepend_before_action :valid_podcast, only: [:show]
  before_action :logged_in_user,  only: [:create, :publish, :unpublish, :update, :destroy]
  before_action :correct_series,  only: [:create]
  before_action :correct_podcast, only: [:publish, :unpublish, :update, :destroy]

  def show
    respond_to do |format|
      format.html
      format.json { render json: @podcast }
    end
  end

  def index
    @podcasts = Podcast.search params
    render json: @podcasts
  end

  def create
    @podcast = @series.podcasts.build(podcast_params)
    if @podcast.save
      render json: @podcast, status: 201
    else
      render json: ErrorSerializer.serialize(@podcast.errors), status: 422
    end
  end

  def update
    if @podcast.update(podcast_params)
      render json: @podcast, status: 200
    else
      render json: ErrorSerializer.serialize(@podcast.errors), status: 422
    end
  end

  def destroy
    @podcast.destroy
    head 204
  end

  def upload
    @podcast = Podcast.find(params[:id])
    chunked_upload = store_podcast_chunk(params)
    response_params = params.slice(:total_size).merge!(chunked_upload.attributes)

    unless chunked_upload.finished
      render json: { upload_status: response_params }, status: 200 and return
    end

    chunked_upload.read do |completed_file|
      @podcast.store_podcast_file(completed_file)
    end
    chunked_upload.cleanup

    if @podcast.valid?
      render json: { upload_status: response_params.merge(completed: true) }, status: 200
    else
      render json: ErrorSerializer.serialize(@podcast.errors), status: 422
    end
  end

  protected

  # return the resource (used in base Publishable class)
  def resource
    @podcast
  end

  private

    def podcast_params
      params.require(:podcast).permit(:title, :podcast_file, :remote_podcast_file_url)
    end

    def correct_podcast
      @podcast ||= current_user.podcasts.find_by id: params[:id]
      render json: ErrorSerializer.serialize(podcast: "is invalid"), status: 422 unless @podcast
    end

    # TODO: refactor with series controller's correct_series method
    def correct_series
      @series ||= current_user.series.find_by id: params[:series_id]
      render json: ErrorSerializer.serialize(series: "is invalid"), status: 422 unless @series
    end

    def valid_podcast
      @podcast = Podcast.find_by id: params[:id]
      render json: ErrorSerializer.serialize(podcast: "is invalid"), status: 422 and return unless @podcast
    end

    def store_podcast_chunk(params)
      chunked_upload = ChunkedUpload.new(@podcast)
      chunked_upload.store_chunk(params)

      chunked_upload
    end
end
