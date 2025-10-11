class ApplicationPlan < Superfeature::Plan
  attr_reader :user, :account

  def initialize(user)
    @user = user
    @account = user.account
  end

  # Examples of different limit types you can use:

  # Hard limit - strict maximum that cannot be exceeded
  # def api_calls
  #   hard_limit quantity: account.api_calls_count, maximum: 1000
  # end

  # Soft limit - has a soft and hard boundary for overages
  # def storage_gb
  #   soft_limit quantity: account.storage_used_gb, soft_limit: 100, hard_limit: 150
  # end

  # Unlimited - no limits (with optional soft limit for technical reasons)
  # def projects
  #   unlimited quantity: account.projects_count
  # end

  # Boolean feature - simple on/off flag
  # def priority_support
  #   enabled
  # end

  # def basic_support
  #   disabled
  # end

  # Named feature - wraps a limit with a display name
  # def advanced_analytics
  #   feature "Advanced Analytics", limit: enabled
  # end
end