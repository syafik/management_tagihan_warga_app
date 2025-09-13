# Redis configuration for caching

if Rails.env.production?
  begin
    # Configure Redis connection
    redis_config = {
      host: ENV.fetch('REDIS_HOST', 'localhost'),
      port: ENV.fetch('REDIS_PORT', 6379),
      db: ENV.fetch('REDIS_DB', 0),
      password: ENV.fetch('REDIS_PASSWORD', nil)
    }

    REDIS = Redis.new(redis_config)

    # Test Redis connection
    REDIS.ping

    # Set Redis as cache store
    Rails.application.config.cache_store = :redis_cache_store, redis_config.merge(
      namespace: 'puriayana_cache',
      expires_in: 1.hour
    )
  rescue StandardError => e
    Rails.logger.error "Redis connection failed: #{e.message}"
    # Fallback to memory store if Redis fails
    Rails.application.config.cache_store = :memory_store
  end
else
  # Use memory store for development/test
  Rails.application.config.cache_store = :memory_store
end
