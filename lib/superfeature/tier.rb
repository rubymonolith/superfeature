module Superfeature
  class Tier
    attr_reader :key, :plan

    delegate :features, :name, :price, :description, to: :plan

    def initialize(key:, plan:, tiers:, user:)
      @key = key
      @plan = plan
      @tiers = tiers
      @user = user
    end

    def to_param
      key.to_s
    end

    def next
      next_key = keys[current_index + 1]
      @tiers.build(next_key, user: @user) if next_key
    end

    def previous
      return nil if current_index == 0
      prev_key = keys[current_index - 1]
      @tiers.build(prev_key, user: @user) if prev_key
    end

    private

    def keys
      @tiers.keys
    end

    def classes
      @tiers.classes
    end

    def current_index
      @current_index ||= keys.index(key)
    end
  end
end
