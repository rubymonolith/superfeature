require 'bigdecimal'

module Superfeature
  # Immutable price object with discount support. Uses BigDecimal internally
  # to avoid floating-point precision errors.
  #
  #   price = Price.new(49.99)
  #   discounted = price.apply_discount("20%")
  #   discounted.amount           # => 39.99
  #   discounted.discount.percent # => 20.0
  #
  class Price
    include Comparable

    attr_reader :amount, :original, :range

    # Creates a new Price.
    # - amount: the price value (converted to BigDecimal)
    # - original: the previous price in a discount chain
    # - discount: the applied Discount::Applied object
    # - range: clamp values to this range (default 0.., use nil for no clamping)
    def initialize(amount, original: nil, discount: nil, range: 0..)
      @amount = clamp_to_range(to_decimal(amount), range)
      @original = original
      @discount = discount
      @range = range
    end

    def discount
      @discount || Discount::NONE
    end

    # Apply a discount from various sources:
    # - String: "25%" → 25% off, "$20" → $20 off
    # - Numeric: 20 → $20 off
    # - Discount object: Discount::Percent.new(25) → 25% off
    # - Any object responding to to_discount
    # - nil: no discount, returns self
    def apply_discount(source)
      return self if source.nil?

      discount = coerce_discount(source)
      discounted = discount.apply(@amount)
      fixed = @amount - discounted
      percent = @amount.zero? ? BigDecimal("0") : (fixed / @amount * 100)

      applied = Discount::Applied.new(discount, fixed:, percent:)

      build_price(discounted, original: self, discount: applied)
    end

    # Apply a fixed dollar discount
    def discount_fixed(amount)
      apply_discount Discount::Fixed.new to_decimal(amount)
    end

    # Set the price to a specific amount
    # Price(300).discount_to(200) is equivalent to Price(300).discount_fixed(100)
    def discount_to(new_amount)
      diff = @amount - to_decimal(new_amount)
      discount_fixed diff.positive? ? diff : 0
    end

    # Apply a percentage discount (decimal, e.g., 0.25 for 25%)
    def discount_percent(percent)
      apply_discount Discount::Percent.new to_decimal(percent) * 100
    end

    def discounted?
      !@original.nil?
    end

    # Returns the undiscounted price (walks up the discount chain)
    def full_price
      @original ? @original.amount : @amount
    end

    def to_formatted_s(decimals: 2)
      "%.#{decimals}f" % @amount.to_f
    end

    def to_f = @amount.to_f
    def to_d = @amount
    def to_i = @amount.to_i
    def to_s = @amount.to_s('F')

    def <=>(other)
      case other
      when Price then @amount <=> other.amount
      when Numeric then @amount <=> to_decimal(other)
      else nil
      end
    end

    def +(other) = build_price(@amount + to_amount(other))
    def -(other) = build_price(@amount - to_amount(other))
    def *(other) = build_price(@amount * to_amount(other))
    def /(other) = build_price(@amount / to_amount(other))
    def -@ = build_price(-@amount)
    def abs = build_price(@amount.abs)

    def zero? = @amount.zero?
    alias free? zero?

    def positive? = @amount.positive?
    alias paid? positive?

    def negative? = @amount.negative?

    def round(decimals = 2) = build_price(@amount.round(decimals))
    def clamp(min, max) = build_price(@amount.clamp(to_amount(min), to_amount(max)))

    # Enables `10 + Price(5)` by converting the numeric to a Price
    def coerce(other)
      case other
      when Numeric then [build_price(other), self]
      else raise TypeError, "#{other.class} can't be coerced into Price"
      end
    end

    def inspect
      if discounted?
        "#<Price #{to_formatted_s} (was #{@original.to_formatted_s}, #{discount.percent.to_f.round(1)}% off)>"
      else
        "#<Price #{to_formatted_s}>"
      end
    end

    private

    def build_price(amount, **options)
      Price.new(amount, range: @range, **options)
    end

    def clamp_to_range(value, range)
      return value unless range

      min = range.begin || -Float::INFINITY
      max = range.end || Float::INFINITY
      value.clamp(min, max)
    end

    def to_decimal(value)
      case value
      when BigDecimal then value
      when Float then BigDecimal(value, 15)
      else BigDecimal(value.to_s)
      end
    end

    def to_amount(other)
      case other
      when Price then other.amount
      when Numeric then to_decimal(other)
      else raise ArgumentError, "Cannot convert #{other.class} to amount"
      end
    end

    def coerce_discount(source)
      case source
      when String then parse_discount_string(source)
      when Numeric then Discount::Fixed.new to_decimal(source)
      else source.to_discount
      end
    end

    def parse_discount_string(str)
      case str
      when nil then Discount::NONE
      when Discount::Percent::PATTERN then Discount::Percent.parse(str)
      when Discount::Fixed::PATTERN then Discount::Fixed.parse(str)
      else raise ArgumentError, "Invalid discount format: #{str.inspect}"
      end
    end
  end
end
