# # Configure Solid Queue Dashboard
# if defined?(SolidQueueDashboard)
#   # Configure the dashboard to use its own assets and layout
#   SolidQueueDashboard::Engine.configure do |config|
#     # Ensure the dashboard uses its own stylesheet
#     config.asset_host = nil
#   end

#   # Override the application controller for SolidQueueDashboard to use proper layout
#   Rails.application.config.after_initialize do
#     if defined?(SolidQueueDashboard::ApplicationController)
#       SolidQueueDashboard::ApplicationController.class_eval do
#         layout 'solid_queue_dashboard/application'

#         # Ensure proper asset loading
#         before_action :load_solid_queue_assets

#         private

#         def load_solid_queue_assets
#           # Ensure Solid Queue's own assets are loaded
#           @solid_queue_stylesheets = ['solid_queue_dashboard/application']
#           @solid_queue_javascripts = ['solid_queue_dashboard/application']
#         end
#       end
#     end
#   end
# end
