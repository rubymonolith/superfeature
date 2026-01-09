require "superfeature/version"
require "superfeature/engine" if defined?(Rails)
require "superfeature/limit"
require "superfeature/feature"
require "superfeature/plan"
require "superfeature/plan/collection"
require "superfeature/discount"
require "superfeature/price"

module Superfeature
  # Convenience methods for creating Discount objects.
  # Use Superfeature::Fixed(20) or after `include Superfeature`, just Fixed(20)
  def Fixed(...) = Discount::Fixed.new(...)
  def Percent(...) = Discount::Percent.new(...)
  def Bundle(...) = Discount::Bundle.new(...)
  module_function :Fixed, :Percent, :Bundle
  public :Fixed, :Percent, :Bundle
end
