require 'rails_helper'

RSpec.describe Featureomatic::Plan do
  let(:plan_klass) do
    Featureomatic.plan do
      def seats
        soft_limit quantity: 37, soft_limit: 100, hard_limit: 110
      end

      def items
        hard_limit quantity: 6, maximum: 100
      end

      def email_support
        enabled
      end

      def phone_support
        feature "Phone Support", limit: hard_limit(quantity: 600, maximum: 100)
      end
    end
  end

  let(:plan) { plan_klass.new }

  it "has phone_support disabled" do
    expect(plan.phone_support).to be_disabled
  end

  it "has email_support enabled" do
    expect(plan.email_support).to be_enabled
  end

  describe "hard limit" do
    subject { plan.items }
    it { is_expected.to be_enabled }
  end

  describe "soft limit" do
    subject { plan.seats }
    it { is_expected.to be_enabled }
  end
end
