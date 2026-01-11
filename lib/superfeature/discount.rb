require 'bigdecimal'

module Superfeature
  # Discount types that can be applied to a Price.
  #
  #   Price(100).apply_discount(Discount::Percent.new(20))  # => 80
  #   Price(100).apply_discount(Discount::Fixed.new(15))    # => 85
  #
  module Discount
    # Base class for all discount types
    class Base
      # Allows any discount to be passed to apply_discount
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

    # Wraps a discount after it's been applied to a price.
    # Holds the computed savings (fixed and percent) for display.
    class Applied
      attr_reader :source, :fixed, :percent

      def initialize(source, fixed:, percent:)
        @source = source
        @fixed = fixed
        @percent = percent
      end

      def to_formatted_s = source.to_formatted_s
      def none? = false

      def to_fixed_s(decimals: 2)
        "%.#{decimals}f" % fixed.to_f
      end

      def to_percent_s(decimals: 0)
        decimals.zero? ? "#{percent.to_i}%" : "%.#{decimals}f%%" % percent.to_f
      end

      def amount
        source.amount if source.respond_to?(:amount)
      end
    end

    # Null object for when no discount is applied.
    # Allows safe method chaining without nil checks.
    class None
      def source = nil
      def fixed = BigDecimal("0")
      def percent = BigDecimal("0")
      def amount = nil
      def to_formatted_s = ""
      def none? = true

      def to_fixed_s(decimals: 2)
        "%.#{decimals}f" % 0
      end

      def to_percent_s(decimals: 0)
        decimals.zero? ? "0%" : "%.#{decimals}f%%" % 0
      end
    end

    NONE = None.new.freeze

    # Fixed dollar amount discount (e.g., "$20 off your first month")
    class Fixed < Base
      PATTERN = /\A\$?\s*(\d+(?:\.\d+)?)\z/

      def self.parse(str)
        str.match(PATTERN) { |m| new(BigDecimal(m.captures.first)) }
      end

      attr_reader :amount

      def initialize(amount)
        @amount = to_decimal(amount)
      end

      def to_formatted_s = @amount.to_i.to_s

      def apply(price)
        to_decimal(price) - @amount
      end
    end

    # Percentage discount (e.g., "20% off annual plans")
    class Percent < Base
      PATTERN = /\A(\d+(?:\.\d+)?)\s*%\z/

      def self.parse(str)
        str.match(PATTERN) { |m| new(BigDecimal(m.captures.first)) }
      end

      attr_reader :percent

      def initialize(percent)
        @percent = to_decimal(percent)
      end

      def to_formatted_s = "#{@percent.to_i}%"

      def apply(price)
        to_decimal(price) * (1 - @percent / 100)
      end
    end

    # Combines multiple discounts applied in sequence
    # (e.g., "$10 off + 20% off for loyalty members")
    class Bundle < Base
      attr_reader :discounts

      def initialize(*discounts)
        @discounts = discounts.flatten
      end

      def apply(price)
        discounts.reduce(to_decimal(price)) { |amt, d| d.to_discount.apply(amt) }
      end
    end

    # Applies a discount then rounds to a "charm" price (e.g., $49.99, $99)
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

    # Builder for charm pricing. Use .up, .down, or .round to set direction.
    #
    #   Discount::Percent.new(20).charm(9).down  # rounds down to nearest $9
    #
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
