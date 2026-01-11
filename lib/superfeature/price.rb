require 'bigdecimal'

module Superfeature
  # Immutable price object with discount support. Uses BigDecimal internally
  # to avoid floating-point precision errors.
  #
  #   price = Price.new(49.99)
  #   discounted = price.apply_discount("20%")
  #   discounted.amount           # => 39.99
  #   discounted.discount.percent # => 20.0
  #
  class Price
    include Comparable

    attr_reader :amount, :previous, :range

    # Creates a new Price.
    # - amount: the price value (converted to BigDecimal)
    # - previous: the previous price in a discount chain
    # - discount: the applied Discount::Applied object
    # - range: clamp values to this range (default 0.., use nil for no clamping)
    def initialize(amount, previous: nil, discount: nil, range: 0..)
      @amount = clamp_to_range(to_decimal(amount), range)
      @previous = previous
      @discount = discount
      @range = range
    end

    def price = self

    def discount
      @discount || Discount::NONE
    end

    # Apply a discount from various sources:
    # - String: "25%" → 25% off, "$20" → $20 off
    # - Numeric: 20 → $20 off
    # - Discount object: Discount::Percent.new(25) → 25% off
    # - Any object responding to to_discount
    # - nil: no discount, returns self
    def apply_discount(*discounts)
      discount, *remaining = discounts.flatten

      if discount.present?
        coerced = coerce_discount(discount)
        discounted = coerced.apply(@amount)
        fixed = @amount - discounted
        percent = @amount.zero? ? BigDecimal("0") : (fixed / @amount * 100)

        applied = Discount::Applied.new(coerced, fixed:, percent:)

        build_price(discounted, previous: self, discount: applied).apply_discount(*remaining)
      else
        price
      end
    end

    # Apply a fixed dollar discount
    def discount_fixed(amount)
      apply_discount Discount::Fixed.new to_decimal(amount)
    end

    # Set the price to a specific amount
    # Price(300).discount_to(200) is equivalent to Price(300).discount_fixed(100)
    def discount_to(new_amount)
      diff = @amount - to_decimal(new_amount)
      discount_fixed diff.positive? ? diff : 0
    end

    # Apply a percentage discount (e.g., 50 for 50% off)
    def discount_percent(percent)
      apply_discount Discount::Percent.new(percent)
    end

    # Apply charm pricing to round to a psychological price ending.
    # Defaults to nearest. Use charm_up or charm_down for explicit direction.
    #
    #   Price(50).charm(9)       # => Price(49) - nearest ending in 9
    #   Price(50).charm_up(9)    # => Price(59) - round up to ending 9
    #   Price(50).charm_down(9)  # => Price(49) - round down to ending 9
    #   Price(50).charm(0.99)    # => Price(49.99) - nearest ending in .99
    #
    def charm(ending)
      apply_discount Discount::Charm::Nearest.new(ending)
    end

    def charm_up(ending)
      apply_discount Discount::Charm::Up.new(ending)
    end

    def charm_down(ending)
      apply_discount Discount::Charm::Down.new(ending)
    end

    def discounted?
      !@previous.nil?
    end

    # Returns the original price (walks all the way back in the discount chain)
    def original
      current = self
      current = current.previous while current.previous
      current
    end

    # Returns an Itemization enumerable for walking the discount chain.
    def itemization
      Itemization.new(self)
    end

    # Returns an Inspector for formatting the price breakdown as text.
    def inspector
      Inspector.new(itemization)
    end

    # Returns the undiscounted price amount (walks up the discount chain)
    def full_price
      original.amount
    end

    def to_formatted_s(decimals: 2)
      "%.#{decimals}f" % @amount.to_f
    end

    def to_f = @amount.to_f
    def to_d = @amount
    def to_i = @amount.to_i
    # Returns display-friendly string: whole numbers without decimals ("19"),
    # cents with 2 decimals ("19.50"). Use to_formatted_s(decimals: 2) for
    # consistent decimal places.
    def to_s
      if @amount % 1 == 0
        @amount.to_i.to_s
      else
        "%.2f" % @amount.to_f
      end
    end

    def <=>(other)
      case other
      when Price then @amount <=> other.amount
      when Numeric then @amount <=> to_decimal(other)
      else nil
      end
    end

    def +(other) = build_price(@amount + to_amount(other))
    def -(other) = build_price(@amount - to_amount(other))
    def *(other) = build_price(@amount * to_amount(other))
    def /(other) = build_price(@amount / to_amount(other))
    def -@ = build_price(-@amount)
    def abs = build_price(@amount.abs)

    def zero? = @amount.zero?
    alias free? zero?

    def positive? = @amount.positive?
    alias paid? positive?

    def negative? = @amount.negative?

    def round(decimals = 2) = build_price(@amount.round(decimals))
    def clamp(min, max) = build_price(@amount.clamp(to_amount(min), to_amount(max)))

    # Enables `10 + Price(5)` by converting the numeric to a Price
    def coerce(other)
      case other
      when Numeric then [build_price(other), self]
      else raise TypeError, "#{other.class} can't be coerced into Price"
      end
    end

    def inspect
      if discounted?
        "#<#{self.class.name} #{to_formatted_s} (was #{@previous.to_formatted_s}, #{discount.percent.to_f.round(1)}% off)>"
      else
        "#<#{self.class.name} #{to_formatted_s}>"
      end
    end

    def pretty_inspect
      receipt = inspector.to_s.lines.map { |line| "# #{line}" }.join
      "#{inspect}\n#\n#{receipt}\n"
    end

    def pretty_print(pp)
      pp.text(pretty_inspect)
    end

    private

    def build_price(*, **)
      Price.new(*, range: @range, **)
    end

    def clamp_to_range(value, range)
      return value unless range

      min = range.begin || -Float::INFINITY
      max = range.end || Float::INFINITY
      value.clamp(min, max)
    end

    def to_decimal(value)
      case value
      when BigDecimal then value
      when Float then BigDecimal(value, 15)
      else BigDecimal(value.to_s)
      end
    end

    def to_amount(other)
      case other
      when Price then other.amount
      when Numeric then to_decimal(other)
      else raise ArgumentError, "Cannot convert #{other.class} to amount"
      end
    end

    def coerce_discount(source)
      case source
      when String then parse_discount_string(source)
      when Numeric then Discount::Fixed.new to_decimal(source)
      else source.to_discount
      end
    end

    def parse_discount_string(str)
      case str
      when nil then Discount::NONE
      when Discount::Percent::PATTERN then Discount::Percent.parse(str)
      when Discount::Fixed::PATTERN then Discount::Fixed.parse(str)
      else raise ArgumentError, "Invalid discount format: #{str.inspect}"
      end
    end
  end

  # Enumerates prices in a discount chain from original to final.
  #
  #   final = Price(100).apply_discount("20%").apply_discount("$10")
  #   itemization = Itemization.new(final)
  #
  #   itemization.original # => Price(100)
  #   itemization.final    # => Price(70)
  #   itemization.count    # => 3
  #   itemization.each { |p| puts p }
  #
  class Itemization
    include Enumerable

    def initialize(price)
      @final = price
    end

    def each(&block)
      return to_enum(:each) unless block_given?

      to_a.each(&block)
    end

    def to_a
      @prices ||= build_chain
    end

    def original
      to_a.first
    end
    alias first original

    def final
      @final
    end
    alias last final

    def size
      to_a.size
    end
    alias count size
    alias length size

    private

    def build_chain
      prices = []
      current = @final

      while current
        prices.unshift(current)
        current = current.previous
      end

      prices
    end
  end

  # Formats a price itemization as a receipt-style text breakdown.
  #
  #   final = Price(100).apply_discount("20%").apply_discount("$10")
  #   puts Inspector.new(final.itemization)
  #
  #   # Output:
  #   #   Original              100.00
  #   #   20% off               -20.00
  #   #                       --------
  #   #   Subtotal               80.00
  #   #   $10 off               -10.00
  #   #                       --------
  #   #   FINAL                  70.00
  #
  class Inspector
    def initialize(itemization, label_width: 20, max_label_width: 30)
      @itemization = itemization
      @label_width = label_width
      @max_label_width = max_label_width
    end

    def to_s
      items = @itemization.to_a
      amount_width = calculate_amount_width(items)
      separator_line = " " * @label_width + "-" * amount_width

      output = []
      output << format_line("Original", items.first.to_formatted_s, amount_width)

      items.drop(1).each_with_index do |price, index|
        fixed = price.discount.fixed
        discount_amount = fixed.negative? ? "+#{fixed.abs.to_f.round(2)}" : "-#{price.discount.to_fixed_s}"
        label = price.discount.to_receipt_s
        output << format_line(label, discount_amount, amount_width)
        output << separator_line

        is_last = index == items.length - 2
        if is_last
          output << format_line("FINAL", price.to_formatted_s, amount_width)
        else
          output << format_line("Subtotal", price.to_formatted_s, amount_width)
        end
      end

      # Handle case with no discounts
      if items.length == 1
        output << separator_line
        output << format_line("FINAL", items.first.to_formatted_s, amount_width)
      end

      output.join("\n")
    end

    private

    def calculate_amount_width(items)
      widths = items.map { |p| p.to_formatted_s.length }
      items.drop(1).each do |p|
        widths << "-#{p.discount.to_fixed_s}".length
      end
      widths.max + 2
    end

    def format_line(label, amount, amount_width)
      if label.length > @max_label_width
        "#{label}\n#{' ' * @label_width}%#{amount_width}s" % [amount]
      else
        "%-#{@label_width}s%#{amount_width}s" % [label, amount]
      end
    end
  end

end
