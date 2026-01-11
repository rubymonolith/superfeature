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
      def to_receipt_s = source.to_receipt_s
      def none? = false

      def to_fixed_s(decimals: 2)
        "%.#{decimals}f" % fixed.abs.to_f
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
      def to_receipt_s = "Discount"
      def none? = true

      def to_fixed_s(decimals: 2)
        "%.#{decimals}f" % 0
      end

      def to_percent_s(decimals: 0)
        decimals.zero? ? "0%" : "%.#{decimals}f%%" % 0
      end
    end

    NONE = None.new.freeze

    # Cumulative savings from original price
    class Savings
      attr_reader :fixed, :percent

      def initialize(fixed:, percent:)
        @fixed = fixed
        @percent = percent
      end

      def to_fixed_s(decimals: 2)
        "%.#{decimals}f" % fixed.abs.to_f
      end

      def to_percent_s(decimals: 0)
        decimals.zero? ? "#{percent.abs.to_i}%" : "%.#{decimals}f%%" % percent.abs.to_f
      end

      def none?
        fixed.zero?
      end
    end

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
      def to_receipt_s = "%.2f off" % @amount.to_f

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
      def to_receipt_s = "#{@percent.to_i}% off"

      def apply(price)
        to_decimal(price) * (1 - @percent / 100)
      end
    end

    # Standalone charm pricing discounts.
    # Rounds price to a psychological ending like .99 or 9.
    #
    #   Charm::Up.new(9).apply(50)      # => 59
    #   Charm::Down.new(9).apply(50)    # => 49
    #   Charm::Nearest.new(9).apply(50) # => 49
    #
    module Charm
      class Up < Base
        attr_reader :ending

        def initialize(ending)
          @ending = to_decimal(ending)
        end

        def apply(price)
          Superfeature::Charm.new(@ending).up(price)
        end

        def to_formatted_s = "Charm up"
        def to_receipt_s = "Charm up"
      end

      class Down < Base
        attr_reader :ending

        def initialize(ending)
          @ending = to_decimal(ending)
        end

        def apply(price)
          Superfeature::Charm.new(@ending).down(price)
        end

        def to_formatted_s = "Charm down"
        def to_receipt_s = "Charm down"
      end

      class Nearest < Base
        attr_reader :ending

        def initialize(ending)
          @ending = to_decimal(ending)
        end

        def apply(price)
          Superfeature::Charm.new(@ending).nearest(price)
        end

        def to_formatted_s = "Charm"
        def to_receipt_s = "Charm"
      end
    end

    # Convenience methods: Discount::Fixed(20) instead of Discount::Fixed.new(20)
    def self.Fixed(amount) = Fixed.new(amount)
    def self.Percent(percent) = Percent.new(percent)
  end
end
