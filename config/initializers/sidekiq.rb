# Sidekiq uses the same Redis as Action Cable / cache (REDIS_URL).
# Default matches config/cable.yml for consistency.
redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
