require "superfeature/version"
require "superfeature/engine"

module Superfeature
  def self.plan(&)
    Class.new(Superfeature::Plan, &)
  end

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

  module Limit
    class Base
      def enabled?
        false
      end

      def disabled?
        not enabled?
      end
    end

    class Hard < Base
      attr_accessor :quantity, :maximum

      def initialize(quantity: , maximum: )
        @quantity = quantity
        @maximum = maximum
      end

      def remaining
        maximum - quantity
      end

      def exceeded?
        quantity > maximum if quantity and maximum
      end

      def enabled?
        not exceeded?
      end
    end

    class Soft < Hard
      attr_accessor :quantity, :soft_limit, :hard_limit

      def initialize(quantity:, soft_limit:, hard_limit:)
        @quantity = quantity
        @soft_limit = soft_limit
        @hard_limit = hard_limit
      end

      def maximum
        @soft_limit
      end
    end

    # Unlimited is treated like a Soft, initialized with infinity values.
    # It is recommended to set a `soft_limit` value based on the technical limitations
    # of your application unless you're running a theoritcal Turing Machine.
    #
    # See https://en.wikipedia.org/wiki/Turing_machine for details.
    class Unlimited < Soft
      INFINITY = Float::INFINITY

      def initialize(quantity: nil, hard_limit: INFINITY, soft_limit: INFINITY, **)
        super(quantity:, hard_limit:, soft_limit:, **)
      end
    end

    class Boolean < Base
      def initialize(enabled:)
        @enabled = enabled
      end

      def enabled?
        @enabled
      end
    end
  end

  class Plan
    def upgrade
    end

    def downgrade
    end

    protected
      def hard_limit(**)
        Limit::Hard.new(**)
      end

      def soft_limit(**)
        Limit::Soft.new(**)
      end

      def unlimited(**)
        Limit::Unlimited.new(**)
      end

      def enabled(value = true, **)
        Limit::Boolean.new enabled: value, **
      end

      def disabled(value = true)
        enabled !value
      end

      def feature(name, **)
        Feature.new(plan: self, name:, **)
      end
  end
end