module Superfeature
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

      def remaining?
        remaining > 0
      end

      def exceeded?
        quantity > maximum if quantity and maximum
      end

      def enabled?
        not exceeded?
      end
    end

    class Soft < Hard
      attr_accessor :soft_limit, :hard_limit

      def initialize(quantity:, soft_limit:, hard_limit:)
        @quantity = quantity
        @soft_limit = soft_limit
        @hard_limit = hard_limit
      end

      def maximum
        @soft_limit
      end
    end

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
end