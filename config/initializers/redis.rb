# Redis configuration for caching

if Rails.env.production?
  # Configure Redis connection
  begin
    REDIS = Redis.new(
      host: ENV.fetch('REDIS_HOST', 'localhost'),
      port: ENV.fetch('REDIS_PORT', 6379),
      db: ENV.fetch('REDIS_DB', 0),
      password: ENV.fetch('REDIS_PASSWORD', nil),
      timeout: 1,
      reconnect_attempts: 3
    )

    # Set Redis as cache store
    Rails.application.configure do
      config.cache_store = :redis_cache_store, {
        host: ENV.fetch('REDIS_HOST', 'localhost'),
        port: ENV.fetch('REDIS_PORT', 6379),
        db: ENV.fetch('REDIS_CACHE_DB', 0),
        password: ENV.fetch('REDIS_PASSWORD', nil),
        namespace: 'puriayana_cache',
        expires_in: 1.hour,
        compress: true,
        compression_threshold: 1024
      }
    end
  rescue StandardError => e
    Rails.logger.error "Redis connection failed: #{e.message}"
    # Fallback to memory store if Redis fails
    Rails.application.configure do
      config.cache_store = :memory_store
    end
  end
end
