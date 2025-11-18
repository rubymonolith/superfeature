require 'rails_helper'

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