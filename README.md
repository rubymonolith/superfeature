# Featureomatic

Features are simple boolean flags that say whether or not they're enabled, right? Not quite. Features can get quite complicated, as you'll read below in the use cases.

This gem makes reasoning through those complexities much more sane by isolating them all into the `app/features` folder as plain 'ol Ruby objects (POROS), that way your team can reason through the features available in an app much better, test them, and do really complicated stuff when needed.

## Use cases

Here's why you should use Featureomatic:

### Turbo app built by a solopreneur deployed to the Apple App Store

If you're deploying a simple Rails Turbo application to the web you might have 20 features that are available for purchase, but when deployed to the Apple App Store, you have to disable certain parts of your website to comply with their draconian app store policies. Featureomatic could disable the features that upset Apple, like links to your support and pricing, so that your app can get approved and stay in compliance.

### B2B Rails app built by a 50 person engineering team for multinational enterprises

Enterprise use-cases are even more complicated. If a package is sold to a multi-national customer with 200 features, they may want to disable 30 of those features for certain teams/groups within that organization for compliance reasons. You end up with a hierarchy that can get as complicated as, "The Zig Bang feature is available to MegaCorp on the Platimum plan, but only for their US entities if their team administrators turn that feature on because of weird compliance reasons".

## Installation

Install the gem by executing the following from your Rails root:

```bash
$ bundle add featureomatic
```

Then run

```bash
$ rails generate featureomatic:install
```

Restart your server and it's off to the races!

First thing you'll want to checkout is the `./app/plans/application_plan.rb` file:

```ruby
class ApplicationPlan < Featureomatic::Plan
  attr_reader :user, :account

  def initialize(user)
    @user = user
    @account = user.account
  end

  def team_size
    hard_limit maximum: 0, quantity: account.users.count
  end

  def moderation
    enabled account.moderation_enabled?
  end

  def support
    disabled
  end
end
```

Here's what it would look like when you add an enterprise plan to the lign up in the ``./app/plans/application_plan.rb`` file.

```ruby
class EnerprisePlan < ApplicationPlan
  def support = enabled
  def saml = enabled
end
```

## Usage

Then you can do things from controllers like:

```ruby
class ModerationController < ApplicationController
  def show
    if feature.moderation.enabled?
      render "moderation"
    else
      redirect_to moderation_upgrade_path
    end
  end

  protected

  def plan = ApplicationPlan.new
  def feature = plan.moderation
end
```

Or from views:

```erb
<h1>Moderation</h1>
<% if feature.enabled? %>
  <p><% render partial: "moderation" %></p>
<% else %>
  <p>Call sales to upgrade to moderation</p>
<% end %>
```

## Comparable libraries

There's a few pretty great feature flag libraries that are worth mentioning so you can better evaluate what's right for you.

### Flipper

https://github.com/jnunemaker/flipper

Flipper is probably the most extensive and mature feature flag libraries. It even comes with its own cloud service. As a library, it concerns itself with:

* Persisting feature flags to Redis, ActiveRecord, or any custom back-end.
* UI for toggling features flags on/off
* Controlling feature flags for everybody, specific people, groups of people, or a percentage of people.

Featureomatic is different in that it:

* Feature flags are testable.
* Features are versioned and tracked as code, which makes it easier to sync between environments if that's a requirement.
* Can handle reasoning about features beyond a simple true/false, including soft limits, app store limitations, or complex feature cascading required by some enterprises.

### Rollout

https://github.com/FetLife/rollout

Roll-out is similar to Flipper, but is backed soley by Redis.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
