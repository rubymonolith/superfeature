# Adds pricing extensions to String
#
#   "49.99".to_price      # => Price(49.99)
#   "$100".to_price       # => Price(100)
#
class String
  def to_price(**options)
    # Strip leading $ and whitespace
    value = self.gsub(/\A\$?\s*/, '')
    Superfeature::Price.new(value, **options)
  end
end
