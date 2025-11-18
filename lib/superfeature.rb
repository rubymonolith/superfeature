require "superfeature/version"
require "superfeature/engine"
require "superfeature/limit"
require "superfeature/feature"
require "superfeature/plan"
require "superfeature/price"

module Superfeature
  def self.plan(&)
    Class.new(Superfeature::Plan, &)
  end
end