require "test_helper"

class NsfwDetectorTest < ActiveSupport::TestCase
  test "rejects when explicit score (porn + hentai) exceeds the reject threshold" do
    assert_equal :rejected, NsfwDetector.status_for("Porn" => 0.8, "Hentai" => 0.1, "Neutral" => 0.1)
  end

  test "sends to review in the middle band" do
    assert_equal :review, NsfwDetector.status_for("Porn" => 0.3, "Hentai" => 0.15)
  end

  test "approves benign images" do
    assert_equal :approved, NsfwDetector.status_for("Neutral" => 0.97, "Drawing" => 0.02, "Porn" => 0.01)
  end

  test "available? honors the test override" do
    NsfwDetector.service_available_override = false
    assert_not NsfwDetector.available?
    NsfwDetector.service_available_override = true
    assert NsfwDetector.available?
  end
end
