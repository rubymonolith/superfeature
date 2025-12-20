module Superfeature
  class Price
    AMOUNT_PRECISION = 2
    PERCENT_PRECISION = 4
    
    attr_reader :amount, :original

    def initialize(amount, original: nil)
      @amount = amount.to_f
      @original = original
    end

    def discount(discount_amount)
      new_amount = ([@amount - discount_amount.to_f, 0].max).round(AMOUNT_PRECISION)
      Price.new(new_amount, original: self)
    end

    def discount_percent(percent)
      discount_amount = @amount * percent.to_f
      new_amount = (@amount - discount_amount).round(AMOUNT_PRECISION)
      Price.new(new_amount, original: self)
    end

    def discount_amount
      return 0.0 unless @original
      (@original.amount - @amount).round(AMOUNT_PRECISION)
    end

    def percent
      return 0.0 unless @original
      return 0.0 if @original.amount.zero?
      ((@original.amount - @amount) / @original.amount).round(PERCENT_PRECISION)
    end

    def savings
      discount_amount
    end

    def discounted?
      !@original.nil?
    end

    def full_price
      @original ? @original.amount : @amount
    end

    def to_f
      @amount
    end

    def to_s
      @amount.to_s
    end
  end
end
