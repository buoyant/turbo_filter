require 'turbo_filter/engine'
require 'turbo_filter/version'
require 'turbo_filter/turbo_filter_controller'
require 'turbo_filter/turbo_filter_helper'
require 'turbo_filter/turbo_filter_query'

ActiveSupport.on_load(:action_view) do
  ::ActionView::Base.send :include, TurboFilter::TurboFilterHelper
end
::ActionController::Base.send :include, TurboFilter::TurboFilterController

module TurboFilter
end
