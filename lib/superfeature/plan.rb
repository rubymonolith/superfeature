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

      def exclusively(method_name)
        klass = self
        original = instance_method(method_name)
        define_method(method_name) do
          original.bind(self).call if instance_of?(klass)
        end
      end
    end

    def key
      self.class.name.split("::").last.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
    end

    alias_method :to_param, :key

    def features
      self.class.features.map { |m| send(m) }
    end

    protected

    def plan(klass)
      klass.new(user)
    end

    def feature(*, **, &)
      Feature.new(*, **, &)
    end

    def enable(flag = true, *, **)
      feature(*, **, limit: Limit::Boolean.new(enabled: flag))
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
  end
end
