require "forwardable"

module Superfeature
  class Feature
    extend Forwardable

    attr_reader :limit
    def_delegators :limit, :enabled?, :disabled?
    def_delegators :limit, :quantity, :maximum, :remaining, :exceeded?

    def initialize(limit: Limit::Base.new)
      @limit = limit
    end

    def enable(value = true)
      @limit = Limit::Boolean.new(enabled: value)
      self
    end

    def disable(value = true)
      enable(!value)
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
