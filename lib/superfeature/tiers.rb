module Superfeature
  class Tiers
    class << self
      def tier(klass, as: nil)
        key = as || infer_key(klass)
        tiers[key] = klass
      end

      def tiers
        @tiers ||= {}
      end

      def keys
        tiers.keys
      end

      def classes
        tiers.values
      end

      def find(key)
        tiers[key.to_sym] || raise(KeyError, "Tier not found: #{key}")
      end

      def build(key, user:)
        klass = find(key)
        plan = klass.new(user)
        Tier.new(key:, plan:, tiers: self, user:)
      end

      def all(user:)
        keys.map { |key| build(key, user:) }
      end

      def first(user:)
        build(keys.first, user:)
      end

      private

      def infer_key(klass)
        klass.name.split("::").last.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
      end
    end
  end
end
