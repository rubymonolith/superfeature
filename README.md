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

### Building a pricing page

```ruby
# In controller
def index
  @plans = Superfeature::Plan::Collection.new(Plans::Free.new(User.new)).to_a
end

# In view
<% @plans.each do |plan| %>
  <div class="plan">
    <h2><%= plan.name %></h2>
    <p class="price">$<%= plan.price %>/month</p>
    <p><%= plan.description %></p>

    <ul>
      <% plan.features.each do |feature| %>
        <li>
          <%= feature.name %>:
          <%= feature.enabled? ? "✓" : "—" %>
        </li>
      <% end %>
    </ul>

    <%= link_to "Select", plan_path(plan) %>
  </div>
<% end %>
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

## Pricing with discounts

The `Price` class helps you work with prices and discounts in views:

```ruby
# Apply discounts
price = Superfeature::Price.new(100.00)
price.discount_fixed(20)      # => $80.00 (fixed $20 off)
price.discount_percent(0.25)  # => $75.00 (25% off)
price.discount("25%")         # => $75.00 (parses string)
price.discount("$20")         # => $80.00 (parses string)
price.discount(20)            # => $80.00 (numeric = dollars)

# Chain discounts
price = Superfeature::Price.new(100.00)
  .discount_percent(0.10)  # 10% off = $90
  .discount_fixed(5.0)     # $5 off = $85

# Read discount info
price.amount           # => 85.0
price.original.amount  # => 90.0 (previous price in chain)
price.fixed_discount   # => 5.0 (dollars saved from last discount)
price.percent_discount # => 0.0556 (percent saved from last discount)
price.discounted?      # => true
```

### Displaying discounts in views

```erb
<% if price.discounted? %>
  <span class="original-price line-through">$<%= price.original.to_formatted_s %></span>
  <span class="sale-price">$<%= price.to_formatted_s %></span>
  <span class="savings"><%= (price.percent_discount * 100).to_i %>% off!</span>
<% else %>
  <span class="price">$<%= price.to_formatted_s %></span>
<% end %>
```

### Custom precision

```ruby
# Configure precision for currency and percentages
price = Superfeature::Price.new(99.999, amount_precision: 3, percent_precision: 6)
price.to_formatted_s  # => "99.999"
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
