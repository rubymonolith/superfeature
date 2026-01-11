# Superfeature

Features are simple boolean flags that say whether or not they're enabled, right? Not quite. Features can get quite complicated, as you'll read below in the use cases.

This gem makes reasoning through those complexities much more sane by isolating them all into the `app/plans` folder as plain 'ol Ruby objects (POROS), that way your team can reason through the features available in an app much better, test them, and do really complicated stuff when needed.

## Use cases

Here's why you should use Superfeature:

### Turbo app built by a solopreneur deployed to the Apple App Store

If you're deploying a simple Rails Turbo application to the web you might have 20 features that are available for purchase, but when deployed to the Apple App Store, you have to disable certain parts of your website to comply with their draconian app store policies. Superfeature could disable the features that upset Apple, like links to your support and pricing, so that your app can get approved and stay in compliance.

### B2B Rails app built by a 50 person engineering team for multinational enterprises

Enterprise use-cases are even more complicated. If a package is sold to a multi-national customer with 200 features, they may want to disable 30 of those features for certain teams/groups within that organization for compliance reasons. You end up with a hierarchy that can get as complicated as, "The Zig Bang feature is available to MegaCorp on the Platimum plan, but only for their US entities if their team administrators turn that feature on because of weird compliance reasons".

## Installation

Install the gem by executing the following from your Rails root:

```bash
$ bundle add superfeature
```

Then run

```bash
$ rails generate superfeature:install
```

Restart your server and it's off to the races!

## Quick Start

### Plans

A plan is a Ruby class that defines what features are available:

```ruby
module Plans
  class Free < Superfeature::Plan
    def name = "Free"
    def description = "Get started for free"
  end
end
```

### Features

Features are methods that return enabled/disabled states:

```ruby
module Plans
  class Free < Superfeature::Plan
    feature def priority_support = disable("Priority support")
    feature def api_access = enable("API access")
  end
end
```

Check features in your app:

```ruby
plan = Plans::Free.new(current_user)
plan.priority_support.enabled?  # => false
plan.api_access.enabled?        # => true
```

### Limits

Features can also be limits with quantities:

```ruby
module Plans
  class Free < Superfeature::Plan
    feature def projects = hard_limit("Projects", quantity: user.projects_count, maximum: 5)
    feature def storage_gb = soft_limit("Storage", quantity: user.storage_gb, soft_limit: 1, hard_limit: 2)
  end
end
```

Check limits:

```ruby
plan.projects.exceeded?   # => true if over 5
plan.projects.remaining   # => how many left
plan.storage_gb.warning?  # => true if between soft and hard limit
```

### Plan Inheritance

Plans inherit from each other. Override features to change them:

```ruby
module Plans
  class Pro < Free
    def name = "Pro"
    def description = "For professionals"

    # Enable what was disabled in Free
    def priority_support = super.enable

    # Increase limits
    def projects = hard_limit("Projects", quantity: user.projects_count, maximum: 100)
  end
end
```

### Navigation Between Plans

Link plans together with `next` and `previous`:

```ruby
module Plans
  class Free < Superfeature::Plan
    def next = plan Pro
  end

  class Pro < Free
    def previous = plan Free
    def next = plan Enterprise
  end

  class Enterprise < Pro
    def previous = plan Pro
  end
end
```

## Pricing

The `Price` class handles monetary values with precision using `BigDecimal` internally:

```ruby
price = Superfeature::Price.new(49.99)
price.amount  # => BigDecimal("49.99")
price.to_f    # => 49.99
price.to_i    # => 49
```

### Adding Price to Plans

```ruby
module Plans
  class Free < Superfeature::Plan
    def price = Price(0)
  end

  class Pro < Free
    def price = Price(29)
  end

  class Enterprise < Pro
    def price = Price(99)
  end
end
```

### Formatting Prices

```ruby
price = Price(29)
price.to_formatted_s            # => "29.00"
price.to_formatted_s(decimals: 0)  # => "29"
```

## Discounts

Apply discounts to prices:

```ruby
price = Price(100)

# Fixed dollar amount off
price.discount_fixed(20).amount  # => 80.0

# Percentage off (0.25 = 25%)
price.discount_percent(0.25).amount  # => 75.0

# Set a target price directly
price.discount_to(79).amount  # => 79.0
```

### Discount Strings

Parse discount strings naturally:

```ruby
price = Price(100)
price.apply_discount("20%").amount   # => 80.0
price.apply_discount("$15").amount   # => 85.0
price.apply_discount(10).amount      # => 90.0 (numeric = dollars off)
```

### Reading Discount Info

After applying a discount, access the details:

```ruby
price = Price(100).apply_discount("25%")

price.amount                  # => 75.0
price.discounted?             # => true
price.original.amount         # => 100.0

price.discount.fixed          # => 25.0 (dollars saved)
price.discount.percent        # => 25.0 (percent saved)
price.discount.to_fixed_s     # => "25.00"
price.discount.to_percent_s   # => "25%"
price.discount.to_formatted_s # => "25%" (natural format)
```

### Discount Objects

For reusable discounts, create `Discount` objects:

```ruby
include Superfeature

summer_sale = Discount::Percent.new(20)
loyalty = Discount::Fixed.new(10)

Price(100).apply_discount(summer_sale).amount  # => 80.0
Price(100).apply_discount(loyalty).amount      # => 90.0
```

Bundle multiple discounts:

```ruby
bundle = Discount::Bundle.new(
  Discount::Fixed.new(10),    # $10 off first
  Discount::Percent.new(20)   # then 20% off
)

Price(100).apply_discount(bundle).amount  # => 72.0 (100 - 10 = 90, then 90 * 0.8 = 72)
```

### Custom Discount Sources

Any object can be a discount if it implements `to_discount`:

```ruby
class Coupon < ApplicationRecord
  def to_discount
    Superfeature::Discount::Percent.new(percent_off)
  end
end

coupon = Coupon.find_by(code: "SAVE20")
price = Price(100).apply_discount(coupon)
price.amount  # => 80.0
```

## Building a Pricing Table

Here's how to put it all together for a pricing page.

### Define Your Plans

```ruby
module Plans
  class Base < Superfeature::Plan
    attr_reader :user

    def initialize(user)
      @user = user
    end

    feature def projects = hard_limit("Projects", quantity: user.projects_count, maximum: 3)
    feature def api_access = disable("API access")
    feature def priority_support = disable("Priority support")
  end

  class Free < Base
    def name = "Free"
    def price = Price(0)
    def next = plan Pro
  end

  class Pro < Free
    def name = "Pro"
    def price = Price(29)

    def projects = hard_limit("Projects", quantity: user.projects_count, maximum: 100)
    def api_access = super.enable

    def previous = plan Free
    def next = plan Enterprise
  end

  class Enterprise < Pro
    def name = "Enterprise"
    def price = Price(99)

    def projects = unlimited("Projects", quantity: user.projects_count)
    def api_access = super.enable
    def priority_support = super.enable

    def previous = plan Pro
  end
end
```

### Add a Promotion

```ruby
class Promotion
  attr_reader :name, :percent_off

  def initialize(name:, percent_off:)
    @name = name
    @percent_off = percent_off
  end

  def to_discount
    Superfeature::Discount::Percent.new(@percent_off)
  end
end
```

### Controller

```ruby
class PricingController < ApplicationController
  def index
    @plans = Superfeature::Plan::Collection.new(Plans::Free.new(User.new)).to_a
    @promo = Promotion.new(name: "Launch Special", percent_off: 20)
  end
end
```

### View

```erb
<h1>Pricing</h1>

<% if @promo %>
  <div class="promo-banner">
    <%= @promo.name %>: Save <%= @promo.percent_off %>% on all plans!
  </div>
<% end %>

<div class="pricing-grid">
  <% @plans.each do |plan| %>
    <div class="plan-card">
      <h2><%= plan.name %></h2>

      <% price = plan.price %>
      <% if @promo && price.positive? %>
        <% discounted = price.apply_discount(@promo) %>
        <p class="price">
          <span class="original">$<%= price.to_formatted_s(decimals: 0) %></span>
          <span class="sale">$<%= discounted.to_formatted_s(decimals: 0) %></span>
          <span class="savings">Save <%= discounted.discount.to_percent_s %></span>
        </p>
      <% else %>
        <p class="price">
          <% if price.free? %>
            Free
          <% else %>
            $<%= price.to_formatted_s(decimals: 0) %>/mo
          <% end %>
        </p>
      <% end %>

      <ul class="features">
        <% plan.features.each do |feature| %>
          <li>
            <% if feature.enabled? %>
              <span class="check">✓</span>
            <% else %>
              <span class="x">✗</span>
            <% end %>
            <%= feature.name %>
          </li>
        <% end %>
      </ul>

      <%= link_to "Choose #{plan.name}", subscribe_path(plan: plan.key), class: "button" %>
    </div>
  <% end %>
</div>
```

This renders a pricing table with:
- Original and discounted prices when a promotion is active
- Feature list with checkmarks
- "Free" label for zero-price plans
- Savings percentage from the discount

## Generated Files

The generator creates the following structure:

### `app/plans/base.rb`

The base plan defines all features with sensible defaults:

```ruby
module Plans
  class Base < Superfeature::Plan
    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Boolean features - simple on/off flags
    feature def priority_support = disable("Priority support", group: "Support")
    feature def phone_support = disable("Phone support", group: "Support")

    # Hard limits - strict maximum that cannot be exceeded
    feature def api_calls = hard_limit("API calls", group: "Limits", quantity: user.api_calls_count, maximum: 1000)

    # Soft limits - has a soft and hard boundary for overages
    feature def storage_gb = soft_limit("Storage", group: "Limits", quantity: user.storage_used_gb, soft_limit: 100, hard_limit: 150)

    # Unlimited - no restrictions
    feature def projects = unlimited("Projects", group: "Limits", quantity: user.projects_count)

    protected

    def feature(name, **options)
      Features::Base.new(name, **options)
    end
  end
end
```

### `app/plans/features/base.rb`

Extends `Superfeature::Feature` with `name` and `group` for display purposes:

```ruby
module Plans
  module Features
    class Base < Superfeature::Feature
      attr_reader :name, :group

      def initialize(name = nil, group: nil, **)
        super(**)
        @name = name
        @group = group
      end
    end
  end
end
```

You can add whatever else you want to a feature class, including logic, calculation methods, new types of limits, and more.

### `app/plans/free.rb` and `app/plans/paid.rb`

Plans are linked together using `next` and `previous` methods:

```ruby
module Plans
  class Free < Base
    def name = "Free"
    def price = 0
    def description = "Get started for free"

    def next = plan Paid
  end
end

module Plans
  class Paid < Free
    def name = "Paid"
    def price = 9.99
    def description = "Full access to all features"

    # Override features from Base to enable them
    def priority_support = super.enable

    def next = nil
    def previous = plan Free
  end
end
```

The `next` and `previous` methods create a linked list of plans that `Superfeature::Plan::Collection` can traverse.

## Usage

### Setting up User#plan

Add a `plan` column to your users table to track which plan they're on:

```ruby
add_column :users, :plan, :string, default: "free"
```

Then add a `plan` method to your User model:

```ruby
class User < ApplicationRecord
  def plan
    @plan ||= Superfeature::Plan::Collection.new(Plans::Free.new(self)).find(plan_key)
  end

  def plan_key
    self[:plan]&.to_sym || :free
  end
end
```

Now you can access features directly from the user:

```ruby
current_user.plan                          # => Collection wrapping Plans::Free or Plans::Paid
current_user.plan.priority_support.enabled? # => false
current_user.plan.upgrades.to_a            # => available upgrade plans
```

### Checking features in controllers

```ruby
class ModerationController < ApplicationController
  def show
    if current_plan.moderation.enabled?
      render "moderation"
    else
      redirect_to upgrade_path
    end
  end

  private

  def current_plan
    @current_plan ||= current_user.plan
  end
  helper_method :current_plan
end
```

### Checking features in views

```erb
<h1>Moderation</h1>
<% if current_plan.moderation.enabled? %>
  <%= render partial: "moderation" %>
<% else %>
  <p>Call sales to upgrade to moderation</p>
<% end %>
```

### Working with Plan::Collection

The `Collection` class wraps a plan and provides navigation and enumeration:

```ruby
# Create a collection starting from any plan
collection = Superfeature::Plan::Collection.new(Plans::Free.new(current_user))

# Find a specific plan by symbol key
collection.find(:paid)  # => Paid plan instance

# Find a specific plan by class
collection.find(Plans::Paid)  # => Paid plan instance

# Get multiple plans with slice
collection.slice(:free, :paid)  # => Array of matching plans
collection.slice(Plans::Free, Plans::Paid)  # => Also works with classes

# Iterate through all plans (includes Enumerable)
collection.each do |plan|
  puts "#{plan.name}: $#{plan.price}"
end

collection.to_a  # All plans as an array
```

### Checking limits

```ruby
plan = current_user.plan

# Hard limits
if plan.api_calls.exceeded?
  render "api_limit_reached"
end

puts plan.api_calls.quantity  # current usage
puts plan.api_calls.maximum   # max allowed
puts plan.api_calls.remaining # how many left

# Boolean features
plan.priority_support.enabled?  # => false
plan.priority_support.disabled? # => true
```

### Preventing inheritance with `exclusively`

When plans inherit from each other, methods are inherited too. Sometimes you want a method to only apply to the exact class it's defined in, not subclasses. Use `exclusively`:

```ruby
module Plans
  class Pro < Basic
    # Only Pro gets this badge, not Enterprise which inherits from Pro
    exclusively def badge = "Most Popular"
  end
end

module Plans
  class Enterprise < Pro
    # badge returns nil here, not "Most Popular"
  end
end
```

## Adding new plans

Generate a new plan:

```bash
$ rails generate superfeature:plan Enterprise
```

This creates `app/plans/enterprise.rb`:

```ruby
module Plans
  class Enterprise < Base
    def name = "Enterprise"
    def price = 0
    def description = "Description for Enterprise plan"

    # Override features from Base to enable them
    # def priority_support = super.enable
    #
    # Conditionally enable/disable based on a boolean:
    # def dark_mode = super.enable(user.premium?)
    # def legacy_feature = super.disable(user.migrated?)

    # Link to adjacent plans for navigation
    # def next = plan NextPlan
    # def previous = plan PreviousPlan
  end
end
```

Then wire it into your plan chain by updating `next` and `previous` methods:

```ruby
# In paid.rb
def next = plan Enterprise

# In enterprise.rb
def previous = plan Paid
```

## Price Reference

### Creating Prices

```ruby
price = Price(49.99)       # convenience method
price = Price.new(49.99)   # standard constructor
```

In Rails, you can also use core extensions:

```ruby
100.discounted_by(20.percent_off)  # => Price(80)
100.discounted_by(20)              # => Price(80)
100.to_price                       # => Price(100)
"$49.99".to_price                  # => Price(49.99)
```

Outside of Rails, opt-in with `require "superfeature/core_ext"`.

### Conversions

```ruby
price.to_f    # => 49.99 (Float)
price.to_i    # => 49 (Integer)
price.to_d    # => BigDecimal("49.99")
price.to_s    # => "49" or "49.99" (display-friendly, omits .00)
price.to_formatted_s(decimals: 2)  # => "49.99" (consistent decimals)
```

### Comparisons

```ruby
Price(100) > Price(50)   # => true
Price(100) == 100        # => true
Price(100) < 200         # => true
```

### Math

```ruby
Price(100) + 20          # => Price(120)
Price(100) - 20          # => Price(80)
Price(100) * 2           # => Price(200)
Price(100) / 4           # => Price(25)
10 + Price(5)            # => Price(15)
```

### Queries

```ruby
Price(0).zero?      # => true
Price(0).free?      # => true (alias)
Price(100).positive? # => true
Price(100).paid?    # => true (alias)
```

## Comparable libraries

There's a few pretty great feature flag libraries that are worth mentioning so you can better evaluate what's right for you.

### Flipper

https://github.com/jnunemaker/flipper

Flipper is probably the most extensive and mature feature flag libraries. It even comes with its own cloud service. As a library, it concerns itself with:

* Persisting feature flags to Redis, ActiveRecord, or any custom back-end.
* UI for toggling features flags on/off
* Controlling feature flags for everybody, specific people, groups of people, or a percentage of people.

Superfeature is different in that it:

* Feature flags are testable.
* Features are versioned and tracked as code, which makes it easier to sync between environments if that's a requirement.
* Can handle reasoning about features beyond a simple true/false, including soft limits, app store limitations, or complex feature cascading required by some enterprises.

### Rollout

https://github.com/FetLife/rollout

Roll-out is similar to Flipper, but is backed soley by Redis.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
