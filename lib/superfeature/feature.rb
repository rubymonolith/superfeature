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
