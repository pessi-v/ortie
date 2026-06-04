require "net/http"

# HTTP client for the nsfwjs sidecar (see nsfw_service/). The sidecar returns the
# five nsfwjs class probabilities; we reject/review based on the explicit score
# (Porn + Hentai), per the architecture doc.
#
# Availability gates the app: registrations and photo uploads are blocked when the
# sidecar is unreachable (see ApplicationController / controllers), so classify is
# only expected to run while the service is up. If it drops mid-flight, classify
# raises Unavailable and ProcessPhotoJob retries.
class NsfwDetector
  Unavailable = Class.new(StandardError)

  REJECT_THRESHOLD = 0.7
  REVIEW_THRESHOLD = 0.3
  HEALTH_TIMEOUT = 1.0
  CLASSIFY_TIMEOUT = 10.0
  AVAILABILITY_TTL = 5.seconds

  # Test hooks (nil in real environments) so tests never hit the network.
  cattr_accessor :service_available_override
  cattr_accessor :classification_override

  class << self
    def base_url
      ENV.fetch("NSFW_SERVICE_URL", "http://localhost:3001")
    end

    def available?
      return service_available_override unless service_available_override.nil?

      Rails.cache.fetch("nsfw_detector/available", expires_in: AVAILABILITY_TTL) { ping }
    end

    def classify(image_path)
      unless classification_override.nil?
        return classification_override.respond_to?(:call) ? classification_override.call(image_path) : classification_override
      end

      new.classify(image_path)
    end

    # Maps the five nsfwjs scores to a moderation status.
    def status_for(scores)
      explicit = scores.fetch("Porn", 0.0) + scores.fetch("Hentai", 0.0)

      if explicit > REJECT_THRESHOLD
        :rejected
      elsif explicit > REVIEW_THRESHOLD
        :review
      else
        :approved
      end
    end

    private

    def ping
      uri = URI.join(base_url, "/health")
      res = Net::HTTP.start(uri.host, uri.port, open_timeout: HEALTH_TIMEOUT, read_timeout: HEALTH_TIMEOUT) do |http|
        http.get(uri.path)
      end
      res.is_a?(Net::HTTPSuccess)
    rescue StandardError
      false
    end
  end

  def classify(image_path)
    self.class.status_for(fetch_scores(image_path))
  end

  private

  def fetch_scores(image_path)
    jpeg = Vips::Image.thumbnail(image_path.to_s, 256).jpegsave_buffer(Q: 90)
    uri = URI.join(self.class.base_url, "/classify")

    request = Net::HTTP::Post.new(uri.path)
    request.body = jpeg
    request["Content-Type"] = "image/jpeg"

    response = Net::HTTP.start(uri.host, uri.port, open_timeout: NsfwDetector::CLASSIFY_TIMEOUT, read_timeout: NsfwDetector::CLASSIFY_TIMEOUT) do |http|
      http.request(request)
    end

    raise Unavailable, "nsfw service returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue Unavailable
    raise
  rescue StandardError => e
    raise Unavailable, "nsfw service unreachable: #{e.class}: #{e.message}"
  end
end
