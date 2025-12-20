require 'rails_helper'

RSpec.describe Superfeature::Feature do
  let(:limit) { Superfeature::Limit::Boolean.new(enabled: true) }

  subject(:feature) { described_class.new(limit:) }

  describe "#enabled?" do
    it "delegates to limit" do
      expect(limit).to receive(:enabled?)
      feature.enabled?
    end
  end

  describe "#disabled?" do
    it "delegates to limit" do
      expect(limit).to receive(:disabled?)
      feature.disabled?
    end
  end

  describe "#boolean?" do
    it { is_expected.to be_boolean }
  end

  describe "#hard_limit?" do
    subject { described_class.new(limit: Superfeature::Limit::Hard.new(quantity: 5, maximum: 10)) }
    it { is_expected.to be_hard_limit }
  end

  describe "#unlimited?" do
    subject { described_class.new(limit: Superfeature::Limit::Unlimited.new) }
    it { is_expected.to be_unlimited }
  end
end
