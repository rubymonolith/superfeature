# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Breaking Changes

- **`Price` now uses `BigDecimal` internally** - All price calculations now use `BigDecimal` to avoid floating-point precision errors. This fixes issues like `49.99 - 20.00` returning `29.990000000000002`.

  ```ruby
  price = Price(49.99)
  price.amount  # => BigDecimal("49.99")
  price.to_f    # => 49.99 (Float)
  price.to_i    # => 49 (Integer)
  price.to_d    # => BigDecimal("49.99")
  ```

- **Renamed `Price#to(amount)` to `Price#discount_to(amount)`** - Clearer naming for setting a target price:

  ```ruby
  # Before
  price = Price(300).to(200)
  
  # After
  price = Price(300).discount_to(200)
  ```

- **Renamed `Price#discount(source)` to `Price#apply_discount(source)`** - The `discount` method is now purely an accessor that returns the applied discount object. Use `apply_discount` to apply discounts.

  ```ruby
  # Before
  price = Price(100).discount(Percent(20))
  
  # After
  price = Price(100).apply_discount(Percent(20))
  ```

- **Removed `Price#fixed_discount` and `Price#percent_discount` methods** - Use `price.discount.fixed` and `price.discount.percent` instead:

  ```ruby
  # Before
  price.fixed_discount    # => 20.0
  price.percent_discount  # => 0.20
  
  # After
  price.discount.fixed    # => 20.0
  price.discount.percent  # => 20.0 (now returns percentage, not decimal)
  ```

- **Removed `Price#discount_source`** - Use `price.discount.source` instead:

  ```ruby
  # Before
  price.discount_source  # => the original discount object
  
  # After
  price.discount.source  # => the original discount object
  ```

- **Removed `amount_precision` and `percent_precision` from `Price`** - Precision is now a display concern. Use the `decimals:` kwarg on formatting methods:

  ```ruby
  # Before
  Price(49.99, amount_precision: 3).to_formatted_s
  
  # After
  Price(49.99).to_formatted_s(decimals: 3)
  ```

- **Added `range` parameter to `Price` (default `0..`)** - Prices are clamped to this range by default. Use `range: nil` to allow negative prices:

  ```ruby
  Price(-10).amount              # => 0.0 (clamped to range 0..)
  Price(-10, range: nil).amount  # => -10.0 (no clamping)
  Price(50, range: 10..100).amount  # => 50.0 (within range)
  ```

### Added

- **`Price#to_d`** - Returns the amount as a `BigDecimal`:

  ```ruby
  Price(49.99).to_d  # => BigDecimal("49.99")
  ```

- **`Price#to_i`** - Returns the amount as an integer (truncated):

  ```ruby
  Price(49.99).to_i  # => 49
  ```

- **`Price#to_s` now formats display-friendly** - Whole numbers omit decimals, cents show 2 decimal places:

  ```ruby
  Price(19).to_s     # => "19"
  Price(19.99).to_s  # => "19.99"
  Price(19.50).to_s  # => "19.50"
  
  # For consistent decimals, use to_formatted_s
  Price(19).to_formatted_s(decimals: 2)  # => "19.00"
  ```

- **`free?` and `paid?` aliases** - More readable alternatives:

  ```ruby
  Price(0).free?    # => true (alias for zero?)
  Price(100).paid?  # => true (alias for positive?)
  ```

- **`Discount::None` null object** - `price.discount` now returns a `None` object instead of `nil` when no discount is applied, enabling safe chaining without `&.`:

  ```ruby
  price = Price(100)
  price.discount.none?         # => true
  price.discount.to_percent_s  # => "0%"
  price.discount.to_fixed_s    # => "0.00"
  price.discount.to_formatted_s # => ""
  ```

- **Comparison operators on `Price`** - Prices can now be compared with other prices or numerics using `<`, `>`, `<=`, `>=`, `==`:

  ```ruby
  Price(100) > Price(50)   # => true
  Price(100) == 100        # => true
  Price(100) < 200         # => true
  
  discounted = Price(100).apply_discount(Percent(20))
  discounted < Price(100)  # => true
  discounted == 80         # => true
  ```

- **Math operators on `Price`** - Prices support `+`, `-`, `*`, `/` with other prices or numerics. Returns a new Price without discount info:

  ```ruby
  Price(100) + 20          # => Price(120)
  Price(100) + Price(50)   # => Price(150)
  Price(100) - 20          # => Price(80)
  Price(100) * 2           # => Price(200)
  Price(100) / 4           # => Price(25)
  ```

- **Unary minus** - Negate a price for credits/refunds:

  ```ruby
  -Price(100, range: nil)  # => Price(-100)
  ```

- **`abs`** - Get absolute value:

  ```ruby
  Price(-100, range: nil).abs  # => Price(100)
  ```

- **`zero?`, `positive?`, `negative?`** - Query price state:

  ```ruby
  Price(0).zero?       # => true
  Price(100).positive? # => true
  Price(-50, range: nil).negative? # => true
  ```

- **`round`** - Round to specified precision:

  ```ruby
  Price(19.999).round     # => Price(20.00)
  Price(19.456).round(2)  # => Price(19.46)
  ```

- **`clamp`** - Constrain price within bounds:

  ```ruby
  Price(150, range: nil).clamp(0, 100)  # => Price(100)
  Price(-50, range: nil).clamp(0, 100)  # => Price(0)
  ```

- **Coercion** - Enables `Numeric + Price` (not just `Price + Numeric`):

  ```ruby
  10 + Price(5)   # => Price(15)
  100 - Price(30) # => Price(70)
  ```

- **Charm pricing on discounts** - Round discounted prices to "charm" endings (e.g., $9.99, $19, $29). `charm()` is itself a discount that defaults to nearest rounding, with `.up` and `.down` for explicit direction:

  ```ruby
  # charm(9) is a discount - defaults to nearest rounding
  Price(100).apply_discount(Percent(50).charm(9))       # => Price(49) (nearest)
  Price(100).apply_discount(Percent(50).charm(9).up)    # => Price(59) (round up)
  Price(100).apply_discount(Percent(50).charm(9).down)  # => Price(49) (round down)

  # Prices ending in .99 ($0.99, $1.99, $2.99...)
  Price(100).apply_discount(Percent(50).charm(0.99))       # => Price(49.99)
  Price(100).apply_discount(Percent(50).charm(0.99).up)    # => Price(50.99)
  Price(100).apply_discount(Percent(50).charm(0.99).down)  # => Price(49.99)

  # Prices ending in 99 ($99, $199, $299...)
  Price(300).apply_discount(Percent(50).charm(99).up)   # => Price(199)
  ```

- **`Discount::Applied` wrapper class** - When a discount is applied, `price.discount` now returns an `Applied` object with computed values and formatting helpers:

  ```ruby
  price = Price(100).apply_discount(Percent(20))
  
  price.discount                # => Discount::Applied
  price.discount.percent        # => 20.0 (computed percent saved)
  price.discount.fixed          # => 20.0 (computed dollars saved)
  price.discount.to_percent_s   # => "20%"
  price.discount.to_fixed_s     # => "20.00"
  price.discount.to_formatted_s # => "20%" (natural format from source)
  price.discount.source         # => the original Discount::Percent object
  ```

- **`to_formatted_s` on `Discount::Fixed` and `Discount::Percent`** - Format discount values for display:

  ```ruby
  Discount::Fixed.new(20).to_formatted_s   # => "20"
  Discount::Percent.new(50).to_formatted_s # => "50%"
  ```

- **`Itemization` class for walking discount chains** - Enumerate all prices in a discount chain from original to final:

  ```ruby
  final = Price(100).apply_discount("20%").apply_discount("$10")
  
  # Access via Price#itemization
  final.itemization.original # => Price(100)
  final.itemization.final    # => Price(70)
  final.itemization.count    # => 3
  
  # Enumerable - iterate from original to final
  final.itemization.each { |p| puts "#{p} (#{p.discount.to_formatted_s})" }
  # 100 ()
  # 80 (20%)
  # 70 ($10)
  
  # Use Enumerable methods
  final.itemization.map(&:to_s)           # => ["100", "80", "70"]
  final.itemization.select(&:discounted?) # => [Price(80), Price(70)]
  ```

- **`Price#previous` for immediate parent price** - Access the price before the most recent discount:

  ```ruby
  final = Price(100).apply_discount("20%").apply_discount("$10")
  
  final.previous          # => Price(80) - immediate parent
  final.previous.previous # => Price(100) - one more step back
  final.original          # => Price(100) - walks all the way back
  ```

- **`Price#original` now returns the true original price** - Walks all the way back to the first price in the chain:

  ```ruby
  final = Price(100).apply_discount("20%").apply_discount("$10")
  
  final.original        # => Price(100) - the starting price
  final.original == final.itemization.first  # => true
  ```

- **`Inspector` class for receipt-style formatting** - Format a price breakdown as a readable receipt. This was made possible by `Itemization`:

  ```ruby
  final = Price(100).apply_discount("20%").apply_discount("$10")
  puts final.inspector
  
  # Output:
  # Original              100.00
  # 20% off               -20.00
  #                     --------
  # Subtotal               80.00
  # 10 off                -10.00
  #                     --------
  # FINAL                  70.00
  ```

  Use `pp` in the console for quick debugging:

  ```ruby
  pp final
  # Original              100.00
  # 20% off               -20.00
  #                     --------
  # Subtotal               80.00
  # 10 off                -10.00
  #                     --------
  # FINAL                  70.00
  ```

  In a Rails ERB template, use `Itemization` to display a price breakdown:

  ```erb
  <table class="price-breakdown">
    <% @price.itemization.each do |price| %>
      <tr>
        <% if price.discounted? %>
          <td><%= price.discount.to_formatted_s %> off</td>
          <td class="amount">-<%= price.discount.to_fixed_s %></td>
        <% else %>
          <td>Original</td>
          <td class="amount"><%= price.to_formatted_s %></td>
        <% end %>
      </tr>
    <% end %>
    <tr class="total">
      <td>Total</td>
      <td class="amount"><%= @price.to_formatted_s %></td>
    </tr>
  </table>
  ```

### Migration Guide

1. Replace all calls to `price.discount(source)` with `price.apply_discount(source)`
2. Replace all calls to `price.to(amount)` with `price.discount_to(amount)`
3. Replace `price.fixed_discount` with `price.discount.fixed`
4. Replace `(price.percent_discount * 100).to_i` with `price.discount.percent.to_i` or `price.discount.to_percent_s`
5. Replace `price.discount_source` with `price.discount.source`
6. Replace `amount_precision:` and `percent_precision:` with `decimals:` kwarg on formatting methods
7. If you relied on negative prices, add `range: nil` to your Price constructor
8. If you were comparing `price.amount` as a Float, note it's now a BigDecimal (use `to_f` if needed)
9. Replace `price.original` with `price.previous` if you need the immediate parent price (one step back). `price.original` now walks all the way back to the first price in the chain.
