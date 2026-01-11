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

    # Applies a discount then rounds to a "charm" price ending (e.g., $19.99, $29, $49)
    # charm(0.99) rounds to prices ending in .99: $0.99, $1.99, $2.99...
    # charm(9) rounds to prices ending in 9: $9, $19, $29...
    class Charmed < Base
      attr_reader :discount, :ending, :direction

      def initialize(discount, ending, direction)
        @discount = discount
        @ending = to_decimal(ending)
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
        return val if val.zero?

        # Determine interval from ending
        # 0.99 → interval of 1 (0.99, 1.99, 2.99...)
        # 9 → interval of 10 (9, 19, 29...)
        # 99 → interval of 100 (99, 199, 299...)
        interval = @ending < 1 ? BigDecimal("1") : BigDecimal("10") ** @ending.to_i.to_s.length

        # Find the candidate (base + ending)
        base = (val / interval).floor * interval
        candidate = base + @ending

        case @direction
        when :up
          candidate < val ? candidate + interval : candidate
        when :down
          candidate > val ? candidate - interval : candidate
        when :nearest
          up_val = candidate < val ? candidate + interval : candidate
          down_val = candidate > val ? candidate - interval : candidate
          (val - down_val).abs <= (up_val - val).abs ? down_val : up_val
        end
      end
    end

    # Charm pricing discount. Applies a discount then rounds to a charm ending.
    # Defaults to nearest rounding. Use .up or .down for explicit direction.
    #
    #   Discount::Percent.new(20).charm(9)       # rounds to nearest price ending in 9
    #   Discount::Percent.new(20).charm(9).up    # rounds up to price ending in 9
    #   Discount::Percent.new(20).charm(9).down  # rounds down to price ending in 9
    #
    class Charm < Base
      attr_reader :discount, :ending

      def initialize(discount, ending)
        @discount = discount
        @ending = to_decimal(ending)
      end

      def apply(price)
        Charmed.new(@discount, @ending, :nearest).apply(price)
      end

      def to_formatted_s = @discount.to_formatted_s

      def up
        Charmed.new(@discount, @ending, :up)
      end
      alias greedy up

      def down
        Charmed.new(@discount, @ending, :down)
      end
      alias generous down
    end

    # Add charm method to Base
    class Base
      def charm(ending)
        Charm.new(self, ending)
      end
    end

    # Convenience methods: Discount::Fixed(20) instead of Discount::Fixed.new(20)
    def self.Fixed(amount) = Fixed.new(amount)
    def self.Percent(percent) = Percent.new(percent)
    def self.Bundle(...) = Bundle.new(...)
  end
end
