# Adds .to_price to Numeric (Integer, Float, BigDecimal)
#
#   10.to_price           # => Price(10)
#   49.99.to_price        # => Price(49.99)
#
class Numeric
  def to_price(**options)
    Superfeature::Price.new(self, **options)
  end
end
