module Cacheable
  extend ActiveSupport::Concern

  private

  # Unified cache helper with HTTP caching (ETag/Last-Modified)
  #
  # This method first checks if the client's HTTP headers (If-None-Match/If-Modified-Since)
  # match the provided `stale_key`. If they match, it halts with a 304 Not Modified.
  # If they don't match, it proceeds to fetch or store the data from the backend cache.
  def cached_render(stale_key:, cache_key:, &block)
    if stale?(etag: stale_key)
      data = Rails.cache.fetch(cache_key, &block)
      render status: :ok, json: data
    end
  end
end
