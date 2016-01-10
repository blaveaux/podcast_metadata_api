FactoryGirl.define do
  factory :podcast do
    transient do
      podcast_file_name "edenlarge.mp3"
    end

    title "Example Podcast"
    podcast_file { fixture_file_upload("test/fixtures/podcasts/#{podcast_file_name}", 'audio/mpeg') }
    user

    factory :podcasts_with_timestamps do
      transient do
        timestamps_count 3
      end

      after(:create) do |podcast, elevator|
        create_list(:timestamp, elevator_timestamps_count, podcast: podcast)
      end
    end
  end
end
