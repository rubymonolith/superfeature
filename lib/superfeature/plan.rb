module Superfeature
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