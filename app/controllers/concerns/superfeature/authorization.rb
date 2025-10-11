module Superfeature::Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :current_plan
  end

  protected
    def current_plan
      ApplicationPlan.new
    end
end