require 'rails_helper'

RSpec.describe Superfeature::Plan::Collection do
  before do
    stub_const("FreePlan", Class.new(Superfeature::Plan) do
      def initialize(user) = @user = user
      def name = "Free"
      def price = 0
      def next = ProPlan.new(@user)
    end)

    stub_const("ProPlan", Class.new(Superfeature::Plan) do
      def initialize(user) = @user = user
      def name = "Pro"
      def price = 10
      def next = EnterprisePlan.new(@user)
      def previous = FreePlan.new(@user)
    end)

    stub_const("EnterprisePlan", Class.new(Superfeature::Plan) do
      def initialize(user) = @user = user
      def name = "Enterprise"
      def price = 100
      def previous = ProPlan.new(@user)
    end)
  end

  let(:user) { double("user") }

  describe "#each" do
    it "iterates through all plans in order" do
      collection = described_class.new(ProPlan.new(user))
      names = collection.map(&:name)
      expect(names).to eq %w[Free Pro Enterprise]
    end

    it "returns an enumerator when no block given" do
      collection = described_class.new(ProPlan.new(user))
      expect(collection.each).to be_a(Enumerator)
    end
  end

  describe "#find" do
    it "finds a plan by key" do
      collection = described_class.new(FreePlan.new(user))
      result = collection.find(:pro_plan)
      expect(result.name).to eq "Pro"
    end

    it "accepts string keys" do
      collection = described_class.new(FreePlan.new(user))
      result = collection.find("enterprise_plan")
      expect(result.name).to eq "Enterprise"
    end

    it "returns nil for unknown key" do
      collection = described_class.new(FreePlan.new(user))
      expect(collection.find(:unknown)).to be_nil
    end
  end

  describe "#next" do
    it "returns a collection wrapping the next plan" do
      collection = described_class.new(FreePlan.new(user))
      expect(collection.next).to be_a(described_class)
      expect(collection.next.name).to eq "Pro"
    end

    it "returns nil for the last plan" do
      collection = described_class.new(EnterprisePlan.new(user))
      expect(collection.next).to be_nil
    end
  end

  describe "#previous" do
    it "returns a collection wrapping the previous plan" do
      collection = described_class.new(ProPlan.new(user))
      expect(collection.previous).to be_a(described_class)
      expect(collection.previous.name).to eq "Free"
    end

    it "returns nil for the first plan" do
      collection = described_class.new(FreePlan.new(user))
      expect(collection.previous).to be_nil
    end
  end

  describe "#upgrades" do
    it "returns an enumerator of plans after the current one" do
      collection = described_class.new(FreePlan.new(user))
      names = collection.upgrades.map(&:name)
      expect(names).to eq %w[Pro Enterprise]
    end

    it "returns empty enumerator for last plan" do
      collection = described_class.new(EnterprisePlan.new(user))
      expect(collection.upgrades.to_a).to be_empty
    end
  end

  describe "#downgrades" do
    it "returns an enumerator of plans before the current one" do
      collection = described_class.new(EnterprisePlan.new(user))
      names = collection.downgrades.map(&:name)
      expect(names).to eq %w[Free Pro]
    end

    it "returns empty enumerator for first plan" do
      collection = described_class.new(FreePlan.new(user))
      expect(collection.downgrades.to_a).to be_empty
    end
  end

  describe "delegation" do
    it "delegates methods to the underlying plan" do
      collection = described_class.new(ProPlan.new(user))
      expect(collection.name).to eq "Pro"
      expect(collection.price).to eq 10
    end

    it "delegates to_param to the plan" do
      collection = described_class.new(ProPlan.new(user))
      expect(collection.to_param).to eq :pro_plan
    end
  end

  describe "Enumerable" do
    it "includes Enumerable methods" do
      collection = described_class.new(FreePlan.new(user))
      expect(collection.to_a.size).to eq 3
      expect(collection.first.name).to eq "Free"
    end
  end
end
