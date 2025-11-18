module Superfeature
  class Feature
    attr_reader :plan, :limit, :name
    delegate :enabled?, :disabled?, to: :limit
    delegate :upgrade, :downgrade, to: :plan

    def initialize(plan:, name:, limit: Limit::Base.new)
      @plan = plan
      @limit = limit
      @name = name
    end
  end
end