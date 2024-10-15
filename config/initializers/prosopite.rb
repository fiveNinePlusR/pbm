if ENV.fetch('RUN_PROSOPITE', false)
  require 'prosopite/middleware/rack'
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)
end