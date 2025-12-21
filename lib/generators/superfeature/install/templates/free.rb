module Plans
  class Free < Base
    def name = "Free"
    def price = 0
    def description = "Get started for free"

    def next = plan(Paid)
  end
end
