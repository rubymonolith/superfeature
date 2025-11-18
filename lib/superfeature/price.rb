module Superfeature
  # A class for handling pricing with a fluent, chainable API.
  # Start with a base price, then chain discount methods.
  #
  # @example Applying a fixed discount
  #   price = Price.new(49.99).discount(20.00)
  #   price.amount           # => 29.99
  #   price.original.amount  # => 49.99
  #   price.discount_amount  # => 20.00
  #   price.percent # => 0.4008 (approximately 40%)
  #
  # @example Applying a percentage discount
  #   price = Price.new(100.00).discount_percent(0.25)
  #   price.amount           # => 75.0
  #   price.original.amount  # => 100.0
  #   price.discount_amount  # => 25.0
  #   price.percent # => 0.25
  #
  # @example No discount
  #   price = Price.new(49.99)
  #   price.amount           # => 49.99
  #   price.discounted?      # => false
  #
  # @example Usage in a view
  #   <div class="product-price">
  #     <% if @price.discounted? %>
  #       <span class="original-price">$<%= @price.original.amount %></span>
  #       <span class="discount-price">$<%= @price.amount %></span>
  #       <span class="discount-badge"><%= (@price.percent * 100).to_i %>% OFF</span>
  #       <span class="savings">Save $<%= @price.discount_amount %></span>
  #     <% else %>
  #       <span class="price">$<%= @price.amount %></span>
  #     <% end %>
  #   </div>
  class Price
    # Rounding precision for monetary amounts (e.g., $19.99)
    AMOUNT_PRECISION = 2
    
    # Rounding precision for percentage calculations (e.g., 0.2545 = 25.45%)
    PERCENT_PRECISION = 4
    
    attr_reader :amount, :original

    # Initialize a new Price
    # @param amount [Numeric] The price amount
    # @param original [Price, nil] The original price before discount (internal use)
    def initialize(amount, original: nil)
      @amount = amount.to_f
      @original = original
    end

    # Apply a fixed dollar discount
    # @param discount_amount [Numeric] The amount to discount
    # @return [Price] A new Price object with the discount applied
    def discount(discount_amount)
      new_amount = ([@amount - discount_amount.to_f, 0].max).round(AMOUNT_PRECISION)
      Price.new(new_amount, original: self)
    end

    # Apply a percentage discount
    # @param percent [Numeric] The discount percentage as a decimal (e.g., 0.25 for 25% off)
    # @return [Price] A new Price object with the discount applied
    def discount_percent(percent)
      discount_amount = @amount * percent.to_f
      new_amount = (@amount - discount_amount).round(AMOUNT_PRECISION)
      Price.new(new_amount, original: self)
    end

    # Returns the dollar amount discounted from the original price
    # @return [Float] The discount amount, or 0 if not discounted
    def discount_amount
      return 0.0 unless @original
      (@original.amount - @amount).round(AMOUNT_PRECISION)
    end

    # Returns the discount as a percentage (0.0 to 1.0)
    # @return [Float] The discount percentage, or 0.0 if not discounted
    def percent
      return 0.0 unless @original
      return 0.0 if @original.amount.zero?
      ((@original.amount - @amount) / @original.amount).round(PERCENT_PRECISION)
    end

    # Returns the amount saved (alias for discount_amount)
    # @return [Float] The amount saved
    def savings
      discount_amount
    end

    # Returns true if this price has a discount applied
    # @return [Boolean]
    def discounted?
      !@original.nil?
    end

    # Returns the full/original price amount
    # Useful for consistently getting the base price regardless of discount state
    # @return [Float]
    def full_price
      @original ? @original.amount : @amount
    end

    # For convenience, allow accessing price as a float
    # @return [Float]
    def to_f
      @amount
    end

    # String representation
    # @return [String]
    def to_s
      @amount.to_s
    end
  end
end