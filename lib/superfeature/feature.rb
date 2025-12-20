module Superfeature
  class Feature
    attr_reader :limit
    delegate :enabled?, :disabled?, to: :limit
    delegate :quantity, :maximum, :remaining, :exceeded?, to: :limit, allow_nil: true

    def initialize(limit: Limit::Base.new)
      @limit = limit
    end

    def enable
      @limit = Limit::Boolean.new(enabled: true)
      self
    end

    def disable
      @limit = Limit::Boolean.new(enabled: false)
      self
    end

    def boolean?
      limit.is_a?(Limit::Boolean)
    end

    def hard_limit?
      limit.instance_of?(Limit::Hard)
    end

    def soft_limit?
      limit.instance_of?(Limit::Soft)
    end

    def unlimited?
      limit.is_a?(Limit::Unlimited)
    end
  end
end
