module Superfeature
  # A class for handling pricing with automatic discount calculations.
  # You can provide either a discount_price OR discount_percent (as a decimal 0.0-1.0), and the other will be calculated.
  #
  # @example Creating pricing with discount price
  #   pricing = Pricing.new(full_price: 100.0, discount_price: 80.0)
  #   pricing.full_price      # => 100.0
  #   pricing.discount_price  # => 80.0
  #   pricing.discount_percent # => 0.2
  #   pricing.savings         # => 20.0
  #
  # @example Creating pricing with discount percent
  #   pricing = Pricing.new(full_price: 100.0, discount_percent: 0.25)
  #   pricing.full_price      # => 100.0
  #   pricing.discount_price  # => 75.0
  #   pricing.discount_percent # => 0.25
  #
  # @example Creating pricing with no discount
  #   pricing = Pricing.new(full_price: 100.0)
  #   pricing.discount_price  # => 100.0
  #   pricing.discount_percent # => 0.0
  #   pricing.discounted?     # => false
  #
  # @example Usage in a view
  #   <div class="product-price">
  #     <% if @pricing.discounted? %>
  #       <span class="original-price">$<%= @pricing.full_price %></span>
  #       <span class="discount-price">$<%= @pricing.discount_price %></span>
  #       <span class="discount-badge"><%= (@pricing.discount_percent * 100).to_i %>% OFF</span>
  #       <span class="savings">Save $<%= @pricing.savings %></span>
  #     <% else %>
  #       <span class="price">$<%= @pricing.full_price %></span>
  #     <% end %>
  #   </div>
  class Pricing
    attr_reader :full_price, :discount_price, :discount_percent

    # Initialize with full_price and optionally discount_price OR discount_percent
    # If both discount_price and discount_percent are provided, discount_price takes precedence
    # @param full_price [Numeric] The original full price
    # @param discount_price [Numeric, nil] The discounted price (optional)
    # @param discount_percent [Numeric, nil] The discount percentage as a decimal 0.0-1.0 (optional, e.g., 0.25 for 25% off)
    def initialize(full_price:, discount_price: nil, discount_percent: nil)
      @full_price = full_price.to_f

      if discount_price.nil? && discount_percent.nil?
        # No discount provided
        @discount_price = @full_price
        @discount_percent = 0.0
      elsif discount_price
        # Discount price provided, calculate percent
        @discount_price = discount_price.to_f
        @discount_percent = calculate_percent_from_price(@full_price, @discount_price)
      else
        # Discount percent provided, calculate price
        @discount_percent = discount_percent.to_f
        @discount_price = calculate_price_from_percent(@full_price, @discount_percent)
      end
    end

    # Returns the amount saved
    def savings
      @full_price - @discount_price
    end

    # Returns true if there's an active discount
    def discounted?
      @discount_percent > 0
    end

    private

    def calculate_percent_from_price(full, discounted)
      return 0.0 if full.zero?
      ((full - discounted) / full).round(4)
    end

    def calculate_price_from_percent(full, percent)
      (full * (1 - percent)).round(2)
    end
  end
end