module Superfeature
  class Plan
    class Collection
      include Enumerable

      attr_reader :plan

      delegate_missing_to :plan
      delegate :to_param, to: :plan

      def initialize(plan)
        @plan = plan
      end

      def each(&)
        return enum_for(:each) unless block_given?

        downgrades.each(&)
        yield self
        upgrades.each(&)
      end

      def find(key)
        slice(key).first
      end

      def slice(*keys)
        keys = keys.map { |key| normalize_key(key) }
        each.select { |p| keys.include?(p.key.to_s) }
      end

      def next
        return nil unless plan.class.method_defined?(:next, false)
        Collection.new(plan.next)
      end

      def previous
        return nil unless plan.class.method_defined?(:previous, false)
        Collection.new(plan.previous)
      end

      def upgrades
        Enumerator.new do |y|
          node = self
          while (node = node.next)
            y << node
          end
        end
      end

      def downgrades
        Enumerator.new do |y|
          node = self
          nodes = []
          while (node = node.previous)
            nodes.unshift(node)
          end
          nodes.each { |n| y << n }
        end
      end

      private

      def normalize_key(key)
        case key
        when Class
          key.name.demodulize.underscore
        when Symbol
          key.to_s
        when String
          key
        end
      end
    end
  end
end
