require 'rails_helper'

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