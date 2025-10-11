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

RSpec.describe Superfeature::Limit::Base do
  subject(:limit) { described_class.new }

  describe "#enabled?" do
    subject { limit.enabled? }
    it { is_expected.to be false }
  end

  describe "#disabled?" do
    subject { limit.disabled? }
    it { is_expected.to be true }
  end
end

RSpec.describe Superfeature::Limit::Hard do
  subject(:limit) { described_class.new(quantity: quantity, maximum: maximum) }

  let(:quantity) { 50 }
  let(:maximum) { 100 }

  describe "#enabled?" do
    subject { limit.enabled? }

    context "when under limit" do
      let(:quantity) { 50 }
      let(:maximum) { 100 }
      it { is_expected.to be true }
    end

    context "when at limit" do
      let(:quantity) { 100 }
      let(:maximum) { 100 }
      it { is_expected.to be true }
    end

    context "when over limit" do
      let(:quantity) { 101 }
      let(:maximum) { 100 }
      it { is_expected.to be false }
    end
  end

  describe "#disabled?" do
    subject { limit.disabled? }

    context "when over limit" do
      let(:quantity) { 101 }
      let(:maximum) { 100 }
      it { is_expected.to be true }
    end
  end

  describe "#exceeded?" do
    subject { limit.exceeded? }

    context "when under limit" do
      let(:quantity) { 50 }
      it { is_expected.to be false }
    end

    context "when at limit" do
      let(:quantity) { 100 }
      it { is_expected.to be false }
    end

    context "when over limit" do
      let(:quantity) { 150 }
      it { is_expected.to be true }
    end
  end

  describe "#remaining" do
    subject { limit.remaining }

    context "when under limit" do
      let(:quantity) { 30 }
      it { is_expected.to eq 70 }
    end

    context "when at limit" do
      let(:quantity) { 100 }
      it { is_expected.to eq 0 }
    end

    context "when over limit" do
      let(:quantity) { 110 }
      it { is_expected.to eq(-10) }
    end
  end

  describe "mutation" do
    it "allows updating quantity" do
      limit.quantity = 75
      expect(limit.remaining).to eq 25
    end
  end
end

RSpec.describe Superfeature::Limit::Soft do
  subject(:limit) { described_class.new(quantity: quantity, soft_limit: soft_limit, hard_limit: hard_limit) }

  let(:quantity) { 50 }
  let(:soft_limit) { 100 }
  let(:hard_limit) { 150 }

  describe "#maximum" do
    subject { limit.maximum }
    it { is_expected.to eq soft_limit }
  end

  describe "#enabled?" do
    subject { limit.enabled? }

    context "when under soft limit" do
      let(:quantity) { 50 }
      it { is_expected.to be true }
    end

    context "when over soft limit but under hard limit" do
      let(:quantity) { 120 }
      it { is_expected.to be false }
    end

    context "when over hard limit" do
      let(:quantity) { 200 }
      it { is_expected.to be false }
    end
  end

  describe "#exceeded?" do
    subject { limit.exceeded? }

    context "when over soft limit" do
      let(:quantity) { 120 }
      it { is_expected.to be true }
    end
  end

  describe "attributes" do
    it { is_expected.to respond_to(:soft_limit) }
    it { is_expected.to respond_to(:hard_limit) }
  end
end

RSpec.describe Superfeature::Limit::Unlimited do
  subject(:limit) { described_class.new(quantity: quantity) }

  let(:quantity) { 1_000_000 }

  describe "#enabled?" do
    subject { limit.enabled? }
    it { is_expected.to be true }
  end

  describe "#exceeded?" do
    subject { limit.exceeded? }
    it { is_expected.to be false }
  end

  describe "with custom soft limit" do
    subject(:limit) { described_class.new(quantity: quantity, soft_limit: 1000) }

    context "when over soft limit" do
      let(:quantity) { 1500 }
      
      it "is disabled" do
        expect(limit).to be_disabled
      end
    end
  end
end

RSpec.describe Superfeature::Limit::Boolean do
  describe "when enabled" do
    subject(:limit) { described_class.new(enabled: true) }

    describe "#enabled?" do
      subject { limit.enabled? }
      it { is_expected.to be true }
    end

    describe "#disabled?" do
      subject { limit.disabled? }
      it { is_expected.to be false }
    end
  end

  describe "when disabled" do
    subject(:limit) { described_class.new(enabled: false) }

    describe "#enabled?" do
      subject { limit.enabled? }
      it { is_expected.to be false }
    end

    describe "#disabled?" do
      subject { limit.disabled? }
      it { is_expected.to be true }
    end
  end
end

RSpec.describe Superfeature::Feature do
  let(:plan) { double("Plan", upgrade: nil, downgrade: nil) }
  let(:limit) { Superfeature::Limit::Boolean.new(enabled: true) }
  
  subject(:feature) { described_class.new(plan: plan, name: "API Access", limit: limit) }

  describe "#name" do
    subject { feature.name }
    it { is_expected.to eq "API Access" }
  end

  describe "#enabled?" do
    subject { feature.enabled? }
    it "delegates to limit" do
      expect(limit).to receive(:enabled?)
      feature.enabled?
    end
  end

  describe "#disabled?" do
    subject { feature.disabled? }
    it "delegates to limit" do
      expect(limit).to receive(:disabled?)
      feature.disabled?
    end
  end

  describe "#upgrade" do
    it "delegates to plan" do
      expect(plan).to receive(:upgrade)
      feature.upgrade
    end
  end

  describe "#downgrade" do
    it "delegates to plan" do
      expect(plan).to receive(:downgrade)
      feature.downgrade
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