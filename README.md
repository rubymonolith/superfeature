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
    feature def priority_support
      disable("Priority support", group: "Support")
    end

    feature def phone_support
      disable("Phone support", group: "Support")
    end

    # Hard limits - strict maximum that cannot be exceeded
    feature def api_calls
      hard_limit("API calls", group: "Limits", quantity: user.api_calls_count, maximum: 1000)
    end

    # Soft limits - has a soft and hard boundary for overages
    feature def storage_gb
      soft_limit("Storage", group: "Limits", quantity: user.storage_used_gb, soft_limit: 100, hard_limit: 150)
    end

    # Unlimited - no restrictions
    feature def projects
      unlimited("Projects", group: "Limits", quantity: user.projects_count)
    end
  
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

### `app/plans/tiers/base.rb`

Registers the order of your plans for pricing pages and upgrades:

```ruby
module Plans
  module Tiers
    class Base < Superfeature::Tiers
      tier Plans::Free
      tier Plans::Paid
    end
  end
end
```

### `app/plans/free.rb` and `app/plans/paid.rb`

Example tier plans:

```ruby
module Plans
  class Free < Base
    def name = "Free"
    def price = 0
    def description = "Get started for free"
  end
end

module Plans
  class Paid < Base
    def name = "Paid"
    def price = 9.99
    def description = "Full access to all features"

    # Override features from Base to enable them
    def priority_support = super.enable
  end
end
```

This logic is useful for determinig if a current user is upgrading or downgrading their plan.

## Usage

### Setting up User#tier and User#plan

Add a `plan` column to your users table to track which tier they're on:

```ruby
add_column :users, :plan, :string, default: "free"
```

Then add `tier` and `plan` methods to your User model:

```ruby
class User < ApplicationRecord
  def tier
    Plans::Tiers::Base.build(plan, user: self)
  end

  delegate :plan, to: :tier, prefix: :current
end
```

Now you can access features directly from the user:

```ruby
current_user.tier          # => Superfeature::Tier (wraps the plan with next/previous)
current_user.current_plan  # => Plans::Free or Plans::Paid (the actual plan instance)

current_user.current_plan.priority_support.enabled?  # => false
current_user.tier.next                               # => Paid tier (for upgrades)
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
    @current_plan ||= Plans::Base.new(current_user)
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

### Working with tiers

```ruby
# Get all tiers for a pricing page
tiers = Plans::Tiers::Base.all(user: current_user)

tiers.each do |tier|
  puts tier.name        # "Free", "Paid"
  puts tier.price       # 0, 9.99
  puts tier.description # "Get started for free", etc.
  
  tier.features.each do |feature|
    puts "#{feature.name}: #{feature.enabled? ? 'Yes' : 'No'}"
  end
end

# Navigate between tiers
tier = Plans::Tiers::Base.build(:free, user: current_user)
tier.next      # => Paid tier
tier.previous  # => nil (first tier)
```

### Checking limits

```ruby
plan = Plans::Base.new(current_user)

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
  end
end
```

Then register it in `app/plans/tiers/base.rb`:

```ruby
module Plans
  module Tiers
    class Base < Superfeature::Tiers
      tier Plans::Free
      tier Plans::Paid
      tier Plans::Enterprise
    end
  end
end
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
