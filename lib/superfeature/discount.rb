module Superfeature
  module Discount
    class Base
      def to_discount = self
    end

    class Fixed < Base
      attr_reader :amount

      def initialize(amount)
        @amount = amount
      end

      def apply(price) = price - amount
    end

    class Percent < Base
      attr_reader :percent

      def initialize(percent)
        @percent = percent
      end

      def apply(price) = price * (1 - percent / 100.0)
    end

    class Bundle < Base
      attr_reader :discounts

      def initialize(*discounts)
        @discounts = discounts.flatten
      end

      def apply(price)
        discounts.reduce(price) { |amt, d| d.to_discount.apply(amt) }
      end
    end

    # Convenience methods: Discount::Fixed(20) instead of Discount::Fixed.new(20)
    def self.Fixed(amount) = Fixed.new(amount)
    def self.Percent(percent) = Percent.new(percent)
    def self.Bundle(...) = Bundle.new(...)
  end
end
