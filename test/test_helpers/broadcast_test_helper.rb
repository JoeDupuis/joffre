module BroadcastTestHelper
  include ActiveJob::TestHelper

  def assert_game_refreshed(game, &block)
    refreshes = capture_turbo_stream_broadcasts(game) do
      block.call
      flush_refresh_broadcasts(game)
    end

    assert_equal [ "refresh" ], refreshes.map { |stream| stream["action"] }
  end

  def assert_game_not_refreshed(game, &block)
    assert_no_turbo_stream_broadcasts(game) do
      block.call
      flush_refresh_broadcasts(game)
    end
  end

  def flush_refresh_broadcasts(game)
    Turbo::StreamsChannel.refresh_debouncer_for(game).wait
    perform_enqueued_jobs
  end

  def discard_refresh_broadcasts(game)
    flush_refresh_broadcasts(game)
    ActionCable.server.pubsub.clear
  end
end
