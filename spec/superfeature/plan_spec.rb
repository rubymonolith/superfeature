require 'rails_helper'

RSpec.describe Superfeature do
  describe ".plan" do
    subject(:plan_klass) do
      described_class.plan do
        def api_calls
          hard_limit quantity: 50, maximum: 100
        end
      end
    end

    it { is_expected.to be_a(Class) }
    it { is_expected.to be < Superfeature::Plan }

    describe "instance" do
      subject { plan_klass.new }
      it { is_expected.to respond_to(:api_calls) }
    end
  end
end

RSpec.describe Superfeature::Plan do
  let(:plan_klass) do
    Superfeature.plan do
      def seats
        soft_limit quantity: 37, soft_limit: 100, hard_limit: 110
      end

      def items
        hard_limit quantity: 6, maximum: 100
      end

      def unlimited_storage
        unlimited quantity: 0
      end

      def email_support
        enabled
      end

      def phone_support
        disabled
      end

      def priority_support
        feature "Priority Support", limit: enabled
      end
    end
  end

  let(:plan) { plan_klass.new }

  describe "#seats (soft limit)" do
    subject { plan.seats }
    it { is_expected.to be_enabled }
    it { is_expected.to be_a(Superfeature::Limit::Soft) }
  end

  describe "#items (hard limit)" do
    subject { plan.items }
    it { is_expected.to be_enabled }
    it { is_expected.to be_a(Superfeature::Limit::Hard) }
  end

  describe "#unlimited_storage" do
    subject { plan.unlimited_storage }
    it { is_expected.to be_enabled }
    it { is_expected.to be_a(Superfeature::Limit::Unlimited) }
  end

  describe "#email_support (enabled)" do
    subject { plan.email_support }
    it { is_expected.to be_enabled }
    it { is_expected.not_to be_disabled }
  end

  describe "#phone_support (disabled)" do
    subject { plan.phone_support }
    it { is_expected.to be_disabled }
    it { is_expected.not_to be_enabled }
  end

  describe "#priority_support (feature)" do
    subject { plan.priority_support }
    
    it { is_expected.to be_a(Superfeature::Feature) }
    it { is_expected.to be_enabled }
    
    describe "#name" do
      subject { plan.priority_support.name }
      it { is_expected.to eq "Priority Support" }
    end
  end

  describe "#upgrade" do
    subject { plan.upgrade }
    it { is_expected.to be_nil }
  end

  describe "#downgrade" do
    subject { plan.downgrade }
    it { is_expected.to be_nil }
  end
end