module Superfeature
  module Discount
    class Base
      def to_discount = self
    end

    class Applied
      attr_reader :source, :fixed, :percent

      def initialize(source, fixed:, percent:)
        @source = source
        @fixed = fixed
        @percent = percent
      end

      def to_formatted_s = source.to_formatted_s

      def to_fixed_s = "%.2f" % fixed

      def to_percent_s = "#{percent.to_i}%"

      def amount
        source.amount if source.respond_to?(:amount)
      end

      def none? = false
    end

    class None
      def source = nil
      def fixed = 0.0
      def percent = 0.0
      def amount = nil
      def to_formatted_s = ""
      def to_fixed_s = "0.00"
      def to_percent_s = "0%"
      def none? = true
    end

    class Fixed < Base
      attr_reader :amount

      def initialize(amount)
        @amount = amount
      end

      def apply(price) = price - amount

      def to_formatted_s = amount.to_i.to_s
    end

    class Percent < Base
      attr_reader :percent

      def initialize(percent)
        @percent = percent
      end

      def apply(price) = price * (1 - percent / 100.0)

      def to_formatted_s = "#{percent.to_i}%"
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
