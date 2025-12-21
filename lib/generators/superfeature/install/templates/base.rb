module Plans
  class Base < Superfeature::Plan
    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Boolean features - simple on/off flags
    # feature def priority_support = disable("Priority support", group: "Support")
    # feature def phone_support = disable("Phone support", group: "Support")

    # Hard limits - strict maximum that cannot be exceeded
    # feature def api_calls = hard_limit("API calls", group: "Limits", quantity: user.api_calls_count, maximum: 1000)

    # Soft limits - has a soft and hard boundary for overages
    # feature def storage_gb = soft_limit("Storage", group: "Limits", quantity: user.storage_used_gb, soft_limit: 100, hard_limit: 150)

    # Unlimited - no restrictions
    # feature def projects = unlimited("Projects", group: "Limits", quantity: user.projects_count)

    protected

    def feature(...) = Features::Base.new(...)
  end
end
