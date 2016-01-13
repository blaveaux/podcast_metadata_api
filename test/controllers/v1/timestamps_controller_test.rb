require 'test_helper'

class V1::TimestampsControllerTest < ActionController::TestCase
  def setup
    # create additional data
    2.times do
      FactoryGirl.create :podcast_with_timestamps
    end
    @podcast = FactoryGirl.create :podcast
    @podcast_with_timestamps = FactoryGirl.create :podcast_with_timestamps
    @timestamps = @podcast_with_timestamps.timestamps
    include_default_accept_headers
  end

  # SHOW

  test "should return valid json on timestamp get" do
    get :show, id: @timestamps.first
    timestamp_response = json_response[:data]
    assert_not_nil timestamp_response
    assert_equal @timestamps.first.id, timestamp_response[:id].to_i

    assert_response 200
  end

  test "should return json errors on invalid timetamp id get" do
    get :show, id: -1
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /Invalid timestamp/, timestamp_errors

    assert_response 403
  end

  # INDEX

  test "index should return valid json on all timestamps" do
    get :index
    timestamp_response = json_response[:data]
    assert_not_nil timestamp_response
    assert_equal Timestamp.count, timestamp_response.count

    assert_response 200
  end

  # CREATE

  test "create should return json errors when not logged in" do
    valid_timestamp_attributes = { start_time: 5, end_time: 10 }
    assert_no_difference '@podcast.timestamps.count' do
      post :create, podcast_id: @podcast, timestamp: valid_timestamp_attributes
    end
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /Not authenticated/, timestamp_errors

    assert_response :unauthorized
  end

  test "create should return json errors on non-logged in users podcast" do
    valid_timestamp_attributes = { start_time: 5, end_time: 10 }
    log_in_as @podcast_with_timestamps.user
    assert_no_difference '@podcast.timestamps.count' do
      post :create, podcast_id: @podcast, timestamp: valid_timestamp_attributes
    end
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /Invalid podcast/, timestamp_errors

    assert_response 403
  end

  test "create should return json errors on invalid attribtues" do
    invalid_timestamp_attributes = { start_time: 10, end_time: 5 }
    log_in_as @podcast.user
    assert_no_difference '@podcast.timestamps.count' do
      post :create, podcast_id: @podcast, timestamp: invalid_timestamp_attributes
    end
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /must be less than start time/, timestamp_errors[:end_time].to_s

    assert_response 422
  end

  test "create should return valid json on valid attributes" do
    valid_timestamp_attributes = { start_time: 5, end_time: 10 }
    log_in_as @podcast.user
    assert_difference '@podcast.timestamps.count', 1 do
      post :create, podcast_id: @podcast, timestamp: valid_timestamp_attributes
    end
    timestamp_response = json_response[:data]
    assert_not_nil timestamp_response
    assert_equal @podcast.timestamps.first.id, timestamp_response[:id].to_i

    assert_response 201
  end

  # UPDATE

  test "update should return json errors when not logged in" do
    valid_timestamp_attributes = { start_time: 10, end_time: nil }
    post :update, id: @timestamps.first, timestamp: valid_timestamp_attributes
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /Not authenticated/, timestamp_errors

    assert_response :unauthorized
  end

  test "update should return json errors on non-logged in users podcast" do
    valid_timestamp_attributes = { start_time: 10, end_time: nil }
    log_in_as @podcast.user
    post :update, id: @timestamps.first, timestamp: valid_timestamp_attributes
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /Invalid timestamp/, timestamp_errors

    assert_response 403
  end

  test "update should return json errors on invalid attributes" do
    invalid_timestamp_attributes = { start_time: @podcast_with_timestamps.end_time, end_time: nil }
    log_in_as @podcast_with_timestamps.user
    post :update, id: @timestamps.first, timestamp: invalid_timestamp_attributes
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /must be within podcast length/, timestamp_errors[:start_time].to_s

    assert_response 422
  end

  test "update should return valid json on valid attributes" do
    valid_timestamp_attributes = { start_time: 10, end_time: nil }
    log_in_as @podcast_with_timestamps.user
    post :update, id: @timestamps.first, timestamp: valid_timestamp_attributes
    timestamp_response = json_response[:data]
    assert_not_nil timestamp_response
    assert_equal valid_timestamp_attributes[:end_time], @timestamps.reload.first.end_time
    assert_equal valid_timestamp_attributes[:end_time], timestamp_response[:attributes][:end_time]

    assert_response 200
  end

  # DESTROY
  
  test "destroy should return authorization error when not logged in" do
    assert_no_difference '@timestamps.count' do
      delete :destroy, id: @timestamps.first
    end
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /Not authenticated/, timestamp_errors

    assert_response :unauthorized
  end

  test "destroy should return json errors on invalid timestamp id" do
    log_in_as @podcast_with_timestamps.user
    assert_no_difference '@timestamps.count' do
      delete :destroy, id: -1
    end
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /Invalid timestamp/, timestamp_errors

    assert_response 403
  end

  test "destroy should return json errors on non-logged in user podcasts timestamp" do
    log_in_as @podcast.user
    assert_no_difference '@timestamps.count' do
      delete :destroy, id: @timestamps.first
    end
    timestamp_errors = json_response[:errors]
    assert_not_nil timestamp_errors
    assert_match /Invalid timestamp/, timestamp_errors

    assert_response 403
  end

  test "destroy should return empty payload on valid timestamp destroy" do
    log_in_as @podcast_with_timestamps.user
    assert_difference '@timestamps.count', -1 do
      delete :destroy, id: @timestamps.first
    end
    assert_empty response.body

    assert_response 204
  end
end