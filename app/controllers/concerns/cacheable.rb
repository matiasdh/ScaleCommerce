# frozen_string_literal: true

module Cacheable
  extend ActiveSupport::Concern

  private

  # Unified cache helper with HTTP caching (ETag/Last-Modified)
  # @param stale_key [Array, Object] Key for HTTP stale? check
  # @param cache_key [Array] Key for Rails.cache
  # @yield Block that returns the data to cache
  def cached_render(stale_key:, cache_key:, &block)
    if stale?(etag: stale_key)
      data = Rails.cache.fetch(cache_key, &block)
      render status: :ok, json: data
    end
  end
end
