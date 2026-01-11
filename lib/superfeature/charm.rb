require 'bigdecimal'

module Superfeature
  # Charm pricing rounds values to psychological price points.
  # For example, $19.99 instead of $20, or $49 instead of $50.
  #
  #   Charm.new(9).up(50)      # => 59 (next price ending in 9)
  #   Charm.new(9).down(50)    # => 49 (previous price ending in 9)
  #   Charm.new(9).nearest(50) # => 49 (closer to 49 than 59)
  #
  #   Charm.new(0.99).up(2.50)   # => 2.99
  #   Charm.new(0.99).down(2.50) # => 1.99
  #
  class Charm
    # Convenience methods to create charm discounts
    # Usage: Charm::Up(9), Charm::Down(9), Charm::Nearest(9)
    def self.Up(ending) = Discount::Charm::Up.new(ending)
    def self.Down(ending) = Discount::Charm::Down.new(ending)
    def self.Nearest(ending) = Discount::Charm::Nearest.new(ending)

    attr_reader :ending

    def initialize(ending)
      @ending = to_decimal(ending)
    end

    def up(value)
      val = to_decimal(value)
      return val if val.zero?

      result = candidate(val)
      result += interval if result < val
      result
    end

    def down(value)
      val = to_decimal(value)
      return val if val.zero?

      result = candidate(val)
      result -= interval if result > val
      result
    end

    def nearest(value)
      val = to_decimal(value)
      return val if val.zero?

      up_val = up(val)
      down_val = down(val)

      distance_down = (val - down_val).abs
      distance_up = (up_val - val).abs
      distance_down <= distance_up ? down_val : up_val
    end

    private

    def to_decimal(value)
      case value
      when BigDecimal then value
      when Float then BigDecimal(value, 15)
      else BigDecimal(value.to_s)
      end
    end

    # Determine interval from ending
    # 0.99 → interval of 1 (0.99, 1.99, 2.99...)
    # 9 → interval of 10 (9, 19, 29...)
    # 99 → interval of 100 (99, 199, 299...)
    def interval
      return BigDecimal("1") if @ending < 1

      digits = @ending.to_i.to_s.length
      BigDecimal("10") ** digits
    end

    def candidate(val)
      base = (val / interval).floor * interval
      base + @ending
    end
  end
end
