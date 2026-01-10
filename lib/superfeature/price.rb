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

    DEFAULT_AMOUNT_PRECISION = 2
    DEFAULT_PERCENT_PRECISION = 4

    attr_reader :amount, :original, :discount_source, :amount_precision, :percent_precision

    def initialize(amount, original: nil, discount_source: nil, discount: nil, amount_precision: DEFAULT_AMOUNT_PRECISION, percent_precision: DEFAULT_PERCENT_PRECISION)
      @amount = amount.to_f
      @original = original
      @discount_source = discount_source
      @discount = discount
      @amount_precision = amount_precision
      @percent_precision = percent_precision
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
      new_amount = [discount_obj.apply(@amount), 0].max.round(@amount_precision)
      fixed_saved = (@amount - new_amount).round(@amount_precision)
      percent_saved = @amount.zero? ? 0.0 : (fixed_saved / @amount * 100).round(@percent_precision)

      applied = Discount::Applied.new(discount_obj, fixed: fixed_saved, percent: percent_saved)

      Price.new(new_amount,
        original: self,
        discount_source: source,
        discount: applied,
        amount_precision: @amount_precision,
        percent_precision: @percent_precision
      )
    end

    # Apply a fixed dollar discount
    def discount_fixed(amount)
      apply_discount(Discount::Fixed.new(amount.to_f))
    end

    # Set the price to a specific amount (calculates discount from current amount)
    # Price(300).to(200) is equivalent to Price(300).discount_fixed(100)
    def to(new_amount)
      discount_fixed([@amount - new_amount.to_f, 0].max)
    end

    # Apply a percentage discount (decimal, e.g., 0.25 for 25%)
    def discount_percent(percent)
      apply_discount(Discount::Percent.new(percent.to_f * 100))
    end

    # Dollars saved from original price
    def fixed_discount
      return 0.0 unless @original
      (@original.amount - @amount).round(@amount_precision)
    end

    # Percent saved as decimal (e.g., 0.25 for 25%)
    def percent_discount
      return 0.0 unless @original
      return 0.0 if @original.amount.zero?
      ((@original.amount - @amount) / @original.amount).round(@percent_precision)
    end

    def discounted?
      !@original.nil?
    end

    def full_price
      @original ? @original.amount : @amount
    end

    # Format amount as string with configured precision
    def to_formatted_s
      "%.#{@amount_precision}f" % @amount
    end

    def to_f
      @amount
    end

    def to_s
      @amount.to_s
    end

    def <=>(other)
      case other
      when Price then @amount <=> other.amount
      when Numeric then @amount <=> other
      else nil
      end
    end

    def +(other)
      Price.new(@amount + to_amount(other), amount_precision: @amount_precision, percent_precision: @percent_precision)
    end

    def -(other)
      Price.new(@amount - to_amount(other), amount_precision: @amount_precision, percent_precision: @percent_precision)
    end

    def *(other)
      Price.new(@amount * to_amount(other), amount_precision: @amount_precision, percent_precision: @percent_precision)
    end

    def /(other)
      Price.new(@amount / to_amount(other), amount_precision: @amount_precision, percent_precision: @percent_precision)
    end

    def inspect
      if discounted?
        "#<Price #{to_formatted_s} (was #{@original.to_formatted_s}, #{(percent_discount * 100).round(1)}% off)>"
      else
        "#<Price #{to_formatted_s}>"
      end
    end

    private

    def to_amount(other)
      case other
      when Price then other.amount
      when Numeric then other
      else raise ArgumentError, "Cannot convert #{other.class} to amount"
      end
    end

    def coerce_discount(source)
      case source
      when String then parse_discount_string(source)
      when Numeric then Discount::Fixed.new(source)
      else source.to_discount
      end
    end

    def parse_discount_string(str)
      case str
      when /\A(\d+(?:\.\d+)?)\s*%\z/
        Discount::Percent.new($1.to_f)
      when /\A\$?\s*(\d+(?:\.\d+)?)\z/
        Discount::Fixed.new($1.to_f)
      else
        raise ArgumentError, "Invalid discount format: #{str.inspect}"
      end
    end
  end
end
