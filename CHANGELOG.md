# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Breaking Changes

- **Renamed `Price#discount(source)` to `Price#apply_discount(source)`** - The `discount` method is now purely an accessor that returns the applied discount object. Use `apply_discount` to apply discounts.

  ```ruby
  # Before
  price = Price(100).discount(Percent(20))
  
  # After
  price = Price(100).apply_discount(Percent(20))
  ```

### Added

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
  -Price(100)  # => Price(-100)
  ```

- **`abs`** - Get absolute value:

  ```ruby
  Price(-100).abs  # => Price(100)
  ```

- **`zero?`, `positive?`, `negative?`** - Query price state:

  ```ruby
  Price(0).zero?       # => true
  Price(100).positive? # => true
  Price(-50).negative? # => true
  ```

- **`round`** - Round to specified precision (defaults to amount_precision):

  ```ruby
  Price(19.999).round     # => Price(20.00)
  Price(19.456).round(2)  # => Price(19.46)
  ```

- **`clamp`** - Constrain price within bounds:

  ```ruby
  Price(150).clamp(0, 100)  # => Price(100)
  Price(-50).clamp(0, 100)  # => Price(0)
  ```

- **Coercion** - Enables `Numeric + Price` (not just `Price + Numeric`):

  ```ruby
  10 + Price(5)   # => Price(15)
  100 - Price(30) # => Price(70)
  ```

- **Charm pricing on discounts** - Round discounted prices to "charm" multiples (e.g., $9.99, $19, $49):

  ```ruby
  # Round to nearest multiple of 9
  Price(99).apply_discount(Percent(50).charm(9).down)   # => Price(45)
  Price(99).apply_discount(Percent(50).charm(9).up)     # => Price(54)
  Price(99).apply_discount(Percent(50).charm(9).round)  # => Price(54) (nearest)

  # Round to nearest 0.99 for $X.99 pricing
  Price(100).apply_discount(Percent(50).charm(0.99).down)  # => Price(49.50)
  Price(100).apply_discount(Percent(50).charm(0.99).up)    # => Price(50.49)
  ```

  The `charm(n)` method returns an object you can inspect:
  
  ```ruby
  charm = Percent(50).charm(0.99)
  charm.multiple  # => 0.99
  charm.discount  # => the Percent(50) discount
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

### Migration Guide

1. Replace all calls to `price.discount(source)` with `price.apply_discount(source)`
2. Replace `(price.percent_discount * 100).to_i` with `price.discount.percent.to_i` or `price.discount.to_percent_s`
3. Replace `price.fixed_discount` with `price.discount.fixed` when you want the computed savings from the applied discount
