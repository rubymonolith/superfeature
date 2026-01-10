require 'bigdecimal'

module Superfeature
  # Convenience method for creating Price objects.
  # Use Superfeature::Price(100) or after `include Superfeature`, just Price(100)
  def Price(amount, **options)
    Price.new(amount, **options)
  end
  module_function :Price
  public :Price

  class Price
    include Comparable

    attr_reader :original, :range

    def initialize(amount, original: nil, discount: nil, range: 0.., precision: 2)
      @precision = precision
      raw = to_decimal(amount)
      @amount = range ? raw.clamp(range.begin || -Float::INFINITY, range.end || Float::INFINITY).round(@precision) : raw.round(@precision)
      @original = original
      @discount = discount
      @range = range
    end

    def amount
      @amount
    end

    def discount
      @discount || Discount::None.new
    end

    # Apply a discount from various sources:
    # - String: "25%" → 25% off, "$20" → $20 off
    # - Numeric: 20 → $20 off
    # - Discount object: Discount::Percent.new(25) → 25% off
    # - Any object responding to to_discount
    # - nil: no discount, returns self
    def apply_discount(source)
      return self if source.nil?

      discount_obj = coerce_discount(source)
      new_amount = discount_obj.apply(@amount)
      fixed_saved = @amount - new_amount
      percent_saved = @amount.zero? ? BigDecimal("0") : (fixed_saved / @amount * 100)

      applied = Discount::Applied.new(discount_obj, fixed: fixed_saved, percent: percent_saved)

      Price.new(new_amount,
        original: self,
        discount: applied,
        range: @range,
        precision: @precision
      )
    end

    # Apply a fixed dollar discount
    def discount_fixed(amount)
      apply_discount(Discount::Fixed.new(to_decimal(amount)))
    end

    # Set the price to a specific amount
    # Price(300).discount_to(200) is equivalent to Price(300).discount_fixed(100)
    def discount_to(new_amount)
      diff = @amount - to_decimal(new_amount)
      discount_fixed(diff > 0 ? diff : 0)
    end

    # Apply a percentage discount (decimal, e.g., 0.25 for 25%)
    def discount_percent(percent)
      apply_discount(Discount::Percent.new(to_decimal(percent) * 100))
    end

    def discounted?
      !@original.nil?
    end

    def full_price
      @original ? @original.amount : @amount
    end

    def to_formatted_s(decimals: 2)
      "%.#{decimals}f" % @amount.to_f
    end

    def to_f
      @amount.to_f
    end

    def to_d
      @amount
    end

    def to_i
      @amount.to_i
    end

    def to_s
      @amount.to_s('F')
    end

    def <=>(other)
      case other
      when Price then @amount <=> other.amount
      when Numeric then @amount <=> to_decimal(other)
      else nil
      end
    end

    def +(other)
      Price.new(@amount + to_amount(other), range: @range, precision: @precision)
    end

    def -(other)
      Price.new(@amount - to_amount(other), range: @range, precision: @precision)
    end

    def *(other)
      Price.new(@amount * to_amount(other), range: @range, precision: @precision)
    end

    def /(other)
      Price.new(@amount / to_amount(other), range: @range, precision: @precision)
    end

    def -@
      Price.new(-@amount, range: @range, precision: @precision)
    end

    def abs
      Price.new(@amount.abs, range: @range, precision: @precision)
    end

    def zero?
      @amount.zero?
    end
    alias free? zero?

    def positive?
      @amount.positive?
    end
    alias paid? positive?

    def negative?
      @amount.negative?
    end

    def round(decimals = 2)
      Price.new(@amount.round(decimals), range: @range, precision: @precision)
    end

    def clamp(min, max)
      Price.new(@amount.clamp(to_amount(min), to_amount(max)), range: @range, precision: @precision)
    end

    def coerce(other)
      case other
      when Numeric then [Price.new(other, range: @range, precision: @precision), self]
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
      when Numeric then Discount::Fixed.new(to_decimal(source))
      else source.to_discount
      end
    end

    def parse_discount_string(str)
      case str
      when /\A(\d+(?:\.\d+)?)\s*%\z/
        Discount::Percent.new(BigDecimal($1))
      when /\A\$?\s*(\d+(?:\.\d+)?)\z/
        Discount::Fixed.new(BigDecimal($1))
      else
        raise ArgumentError, "Invalid discount format: #{str.inspect}"
      end
    end
  end
end
