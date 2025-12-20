module Superfeature
  class Plan
    class << self
      def features
        ((superclass.respond_to?(:features) ? superclass.features : []) + @features.to_a).uniq
      end

      def feature(method_name)
        (@features ||= []) << method_name
        method_name
      end
    end

    protected

    def feature(*, **, &)
      Feature.new(*, **, &)
    end

    def enable(*, **)
      feature(*, **, limit: Limit::Boolean.new(enabled: true))
    end

    def disable(*, **)
      feature(*, **, limit: Limit::Boolean.new(enabled: false))
    end

    def hard_limit(*, quantity:, maximum:, **)
      feature(*, **, limit: Limit::Hard.new(quantity:, maximum:))
    end

    def soft_limit(*, quantity:, soft_limit:, hard_limit:, **)
      feature(*, **, limit: Limit::Soft.new(quantity:, soft_limit:, hard_limit:))
    end

    def unlimited(*, quantity: nil, **)
      feature(*, **, limit: Limit::Unlimited.new(quantity:))
    end

    public

    def features
      self.class.features.map { |m| send(m) }
    end
  end
end
