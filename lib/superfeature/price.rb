module Superfeature
  # Convenience method for creating Price objects.
  # Use Superfeature::Price(100) or after `include Superfeature`, just Price(100)
  def Price(amount, **options)
    Price.new(amount, **options)
  end
  module_function :Price
  public :Price

  class Price
    DEFAULT_AMOUNT_PRECISION = 2
    DEFAULT_PERCENT_PRECISION = 4

    attr_reader :amount, :original, :amount_precision, :percent_precision

    def initialize(amount, original: nil, amount_precision: DEFAULT_AMOUNT_PRECISION, percent_precision: DEFAULT_PERCENT_PRECISION)
      @amount = amount.to_f
      @original = original
      @amount_precision = amount_precision
      @percent_precision = percent_precision
    end

    # Apply a discount by parsing the input:
    # - "25%" → 25% off
    # - "$20" → $20 off
    # - 20 → $20 off (numeric = always dollars)
    def discount(value)
      case value
      # Matches: "25%", "10.5%", "100 %"
      when /\A(\d+(?:\.\d+)?)\s*%\z/
        discount_percent($1.to_f / 100)
      # Matches: "$20", "$ 20", "20", "19.99", "$19.99"
      when /\A\$?\s*(\d+(?:\.\d+)?)\z/
        discount_fixed($1.to_f)
      when Numeric
        discount_fixed(value)
      else
        raise ArgumentError, "Invalid discount format: #{value.inspect}"
      end
    end

    # Apply a fixed dollar discount
    def discount_fixed(amount)
      new_amount = ([@amount - amount.to_f, 0].max).round(@amount_precision)
      Price.new(new_amount, original: self, amount_precision: @amount_precision, percent_precision: @percent_precision)
    end

    # Set the price to a specific amount (calculates discount from current amount)
    # Price(300).to(200) is equivalent to Price(300).discount_fixed(100)
    def to(new_amount)
      discount_fixed([@amount - new_amount.to_f, 0].max)
    end

    # Apply a percentage discount (decimal, e.g., 0.25 for 25%)
    def discount_percent(percent)
      discount_amount = @amount * percent.to_f
      new_amount = (@amount - discount_amount).round(@amount_precision)
      Price.new(new_amount, original: self, amount_precision: @amount_precision, percent_precision: @percent_precision)
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

    def inspect
      if discounted?
        "#<Price #{to_formatted_s} (was #{@original.to_formatted_s}, #{(percent_discount * 100).round(1)}% off)>"
      else
        "#<Price #{to_formatted_s}>"
      end
    end
  end
end
