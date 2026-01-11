# Adds pricing extensions to Numeric (Integer, Float, BigDecimal)
#
#   100.discounted_by(20.percent_off)  # => Price(80)
#   100.discounted_by(20)              # => Price(80)
#   100.to_price                       # => Price(100)
#
class Numeric
  def to_price(**options)
    Superfeature::Price.new(self, **options)
  end

  def percent_off
    Superfeature::Discount::Percent.new(self)
  end

  def discounted_by(discount)
    to_price.apply_discount(discount)
  end
end
