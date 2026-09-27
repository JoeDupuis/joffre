module BroadcastTestHelper
  include ActiveJob::TestHelper

  def assert_game_refreshed(game, &block)
    refreshes = capture_turbo_stream_broadcasts(game) { perform_enqueued_jobs(&block) }

    assert_equal [ "refresh" ], refreshes.map { |stream| stream["action"] }.uniq
  end

  def assert_game_not_refreshed(game, &block)
    assert_no_turbo_stream_broadcasts(game) { perform_enqueued_jobs(&block) }
  end
end
