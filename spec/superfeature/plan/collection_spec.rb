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
    it "finds a plan by symbol key" do
      collection = described_class.new(FreePlan.new(user))
      result = collection.find(:pro_plan)
      expect(result.name).to eq "Pro"
    end

    it "finds a plan by class" do
      collection = described_class.new(FreePlan.new(user))
      result = collection.find(EnterprisePlan)
      expect(result.name).to eq "Enterprise"
    end

    it "returns nil for unknown key" do
      collection = described_class.new(FreePlan.new(user))
      expect(collection.find(:unknown)).to be_nil
    end
  end

  describe "#slice" do
    it "returns plans matching symbol keys" do
      collection = described_class.new(FreePlan.new(user))
      result = collection.slice(:free_plan, :enterprise_plan)
      expect(result.map(&:name)).to eq %w[Free Enterprise]
    end

    it "returns plans matching classes" do
      collection = described_class.new(FreePlan.new(user))
      result = collection.slice(ProPlan, EnterprisePlan)
      expect(result.map(&:name)).to eq %w[Pro Enterprise]
    end

    it "returns empty array for no matches" do
      collection = described_class.new(FreePlan.new(user))
      expect(collection.slice(:unknown)).to be_empty
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
