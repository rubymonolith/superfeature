require "superfeature/version"
require "superfeature/engine" if defined?(Rails)
require "superfeature/limit"
require "superfeature/feature"
require "superfeature/plan"
require "superfeature/plan/collection"
require "superfeature/round"
require "superfeature/discount"
require "superfeature/price"

module Superfeature
  # Mix this in to get Price, Fixed, Percent helpers.
  #
  #   class Plan
  #     include Superfeature::Pricing
  #
  #     def monthly_price
  #       Price(29).apply_discount(Percent(20))
  #     end
  #   end
  #
  module Pricing
    def Price(...) = Superfeature::Price.new(...)
    def Fixed(...) = Discount::Fixed.new(...)
    def Percent(...) = Discount::Percent.new(...)
    Round = Superfeature::Round
  end

  include Pricing
  extend Pricing
end
