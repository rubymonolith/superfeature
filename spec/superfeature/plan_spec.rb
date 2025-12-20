require 'rails_helper'

RSpec.describe Superfeature::Plan do
  let(:plan_klass) do
    Class.new(Superfeature::Plan) do
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
        enable
      end

      def phone_support
        disable
      end
    end
  end

  let(:plan) { plan_klass.new }

  describe "#seats (soft limit)" do
    subject { plan.seats }
    it { is_expected.to be_enabled }
    it { is_expected.to be_a(Superfeature::Feature) }
    it { is_expected.to be_soft_limit }
  end

  describe "#items (hard limit)" do
    subject { plan.items }
    it { is_expected.to be_enabled }
    it { is_expected.to be_a(Superfeature::Feature) }
    it { is_expected.to be_hard_limit }
  end

  describe "#unlimited_storage" do
    subject { plan.unlimited_storage }
    it { is_expected.to be_enabled }
    it { is_expected.to be_a(Superfeature::Feature) }
    it { is_expected.to be_unlimited }
  end

  describe "#email_support (enabled)" do
    subject { plan.email_support }
    it { is_expected.to be_a(Superfeature::Feature) }
    it { is_expected.to be_enabled }
    it { is_expected.not_to be_disabled }
  end

  describe "#phone_support (disabled)" do
    subject { plan.phone_support }
    it { is_expected.to be_a(Superfeature::Feature) }
    it { is_expected.to be_disabled }
    it { is_expected.not_to be_enabled }
  end

  describe "inheritance" do
    let(:base_plan) do
      Class.new(Superfeature::Plan) do
        def basic
          enable
        end

        def premium
          disable
        end
      end
    end

    let(:upgraded_plan) do
      Class.new(base_plan) do
        def premium
          enable
        end
      end
    end

    it "inherits features from parent" do
      expect(upgraded_plan.new.basic).to be_enabled
    end

    it "can override features" do
      expect(base_plan.new.premium).to be_disabled
      expect(upgraded_plan.new.premium).to be_enabled
    end
  end
end
