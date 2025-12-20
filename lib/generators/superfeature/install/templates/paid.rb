module Plans
  class Paid < Base
    def name = "Paid"
    def price = 9.99
    def description = "Full access to all features"

    # Override features from Base to enable them
    # def priority_support = super.enable
  end
end
