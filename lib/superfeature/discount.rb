require 'bigdecimal'

module Superfeature
  module Discount
    class Base
      def to_discount = self

      private

      def to_decimal(value)
        case value
        when BigDecimal then value
        when Float then BigDecimal(value, 15)
        else BigDecimal(value.to_s)
        end
      end
    end

    class Applied
      attr_reader :source, :fixed, :percent

      def initialize(source, fixed:, percent:)
        @source = source
        @fixed = fixed
        @percent = percent
      end

      def to_formatted_s = source.to_formatted_s

      def to_fixed_s(decimals: 2) = "%.#{decimals}f" % fixed.to_f

      def to_percent_s(decimals: 0) = decimals.zero? ? "#{percent.to_i}%" : "%.#{decimals}f%%" % percent.to_f

      def amount
        source.amount if source.respond_to?(:amount)
      end

      def none? = false
    end

    class None
      def source = nil
      def fixed = BigDecimal("0")
      def percent = BigDecimal("0")
      def amount = nil
      def to_formatted_s = ""
      def to_fixed_s(decimals: 2) = "%.#{decimals}f" % 0
      def to_percent_s(decimals: 0) = decimals.zero? ? "0%" : "%.#{decimals}f%%" % 0
      def none? = true
    end

    class Fixed < Base
      attr_reader :amount

      def initialize(amount)
        @amount = to_decimal(amount)
      end

      def apply(price) = to_decimal(price) - @amount

      def to_formatted_s = @amount.to_i.to_s
    end

    class Percent < Base
      attr_reader :percent

      def initialize(percent)
        @percent = to_decimal(percent)
      end

      def apply(price) = to_decimal(price) * (1 - @percent / 100)

      def to_formatted_s = "#{@percent.to_i}%"
    end

    class Bundle < Base
      attr_reader :discounts

      def initialize(*discounts)
        @discounts = discounts.flatten
      end

      def apply(price)
        discounts.reduce(to_decimal(price)) { |amt, d| d.to_discount.apply(amt) }
      end
    end

    # Charmed discount wrapper - applies discount then rounds to charm price
    class Charmed < Base
      attr_reader :discount, :multiple, :direction

      def initialize(discount, multiple, direction)
        @discount = discount
        @multiple = to_decimal(multiple)
        @direction = direction
      end

      def apply(price)
        result = @discount.apply(price)
        charm_round(result)
      end

      def to_formatted_s = @discount.to_formatted_s

      private

      def charm_round(value)
        val = to_decimal(value)
        case @direction
        when :up
          (@multiple * (val / @multiple).ceil).round(2)
        when :down
          (@multiple * (val / @multiple).floor).round(2)
        when :nearest
          (@multiple * (val / @multiple).round).round(2)
        end
      end
    end

    # Charm builder - returned by discount.charm(n)
    class Charm
      attr_reader :discount, :multiple

      def initialize(discount, multiple)
        @discount = discount
        @multiple = multiple
      end

      def up
        Charmed.new(@discount, @multiple, :up)
      end
      alias greedy up

      def down
        Charmed.new(@discount, @multiple, :down)
      end
      alias generous down

      def round
        Charmed.new(@discount, @multiple, :nearest)
      end
    end

    # Add charm method to Base
    class Base
      def charm(multiple)
        Charm.new(self, multiple)
      end
    end

    # Convenience methods: Discount::Fixed(20) instead of Discount::Fixed.new(20)
    def self.Fixed(amount) = Fixed.new(amount)
    def self.Percent(percent) = Percent.new(percent)
    def self.Bundle(...) = Bundle.new(...)
  end
end
