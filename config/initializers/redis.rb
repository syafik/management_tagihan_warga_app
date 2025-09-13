# Redis configuration for caching and session store

if Rails.env.production?
  # Configure Redis connection
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
    
    # Use Redis for session store
    config.session_store :redis_session_store, {
      key: '_puriayana_session',
      redis: {
        host: ENV.fetch('REDIS_HOST', 'localhost'),
        port: ENV.fetch('REDIS_PORT', 6379),
        db: ENV.fetch('REDIS_SESSION_DB', 1),
        password: ENV.fetch('REDIS_PASSWORD', nil)
      },
      expire_after: 2.weeks,
      secure: Rails.env.production?,
      httponly: true,
      same_site: :lax
    }
  end
end