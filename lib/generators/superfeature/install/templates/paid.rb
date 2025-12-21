module Plans
  class Paid < Free
    def name = "Paid"
    def price = 9.99
    def description = "Full access to all features"

    # Override features from Base to enable them
    # def priority_support = super.enable

    def next = nil
    def previous = plan(Free)
  end
end
