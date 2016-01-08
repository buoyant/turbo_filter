require 'turbo_filter/engine'
require "turbo_filter/version"
require "turbo_filter/turbo_filter_query"
require 'turbo_filter/turbo_filter_helper'

ActiveSupport.on_load(:action_view) do
  ::ActionView::Base.send :include, ActionView::Helpers::TurboFilterHelper
end
::ActionController::Base.send :include, ActionView::Helpers::TurboFilterHelper

module TurboFilter
end
