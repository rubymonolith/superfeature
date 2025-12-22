module Superfeature
  class Plan
    class Collection
      include Enumerable

      def initialize(plan)
        @plan = plan
      end

      def each(&)
        return enum_for(:each) unless block_given?

        downgrades.each(&)
        yield @plan
        upgrades.each(&)
      end

      def find(key)
        key = normalize_key(key)
        each.find { |p| p.key.to_s == key }
      end

      def slice(*keys)
        keys.filter_map { |key| find(key) }
      end

      private

      def next_plan
        return nil unless @plan.class.method_defined?(:next, false)
        @plan.next
      end

      def previous_plan
        return nil unless @plan.class.method_defined?(:previous, false)
        @plan.previous
      end

      def upgrades
        Enumerator.new do |y|
          node = @plan
          while (node = node.class.method_defined?(:next, false) ? node.next : nil)
            y << node
          end
        end
      end

      def downgrades
        Enumerator.new do |y|
          node = @plan
          nodes = []
          while (node = node.class.method_defined?(:previous, false) ? node.previous : nil)
            nodes.unshift(node)
          end
          nodes.each { |n| y << n }
        end
      end

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
