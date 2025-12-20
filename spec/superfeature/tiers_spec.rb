require 'rails_helper'

RSpec.describe Superfeature::Tiers do
  before do
    stub_const("FreePlan", Class.new(Superfeature::Plan) do
      def initialize(user) = @user = user
      def name = "Free"
      def price = 0
      def description = "Free tier"
    end)
    stub_const("ProPlan", Class.new(Superfeature::Plan) do
      def initialize(user) = @user = user
      def name = "Pro"
      def price = 10
      def description = "Pro tier"
    end)
    stub_const("EnterprisePlan", Class.new(Superfeature::Plan) do
      def initialize(user) = @user = user
      def name = "Enterprise"
      def price = 100
      def description = "Enterprise tier"
    end)

    stub_const("TestTiers", Class.new(Superfeature::Tiers) do
      tier FreePlan, as: :free
      tier ProPlan, as: :pro
      tier EnterprisePlan, as: :enterprise
    end)
  end

  describe ".tier" do
    it "registers a tier with a key" do
      expect(TestTiers.tiers).to eq({ free: FreePlan, pro: ProPlan, enterprise: EnterprisePlan })
    end
  end

  describe ".keys" do
    it "returns all tier keys" do
      expect(TestTiers.keys).to eq [:free, :pro, :enterprise]
    end
  end

  describe ".classes" do
    it "returns all plan classes" do
      expect(TestTiers.classes).to eq [FreePlan, ProPlan, EnterprisePlan]
    end
  end

  describe ".find" do
    it "returns plan class by key" do
      expect(TestTiers.find(:pro)).to eq ProPlan
    end

    it "accepts string keys" do
      expect(TestTiers.find("pro")).to eq ProPlan
    end

    it "raises KeyError for unknown key" do
      expect { TestTiers.find(:unknown) }.to raise_error(KeyError, "Tier not found: unknown")
    end
  end

  describe ".build" do
    let(:user) { double("user") }
    subject { TestTiers.build(:pro, user:) }

    it "returns a Tier" do
      expect(subject).to be_a(Superfeature::Tier)
    end

    it "has the correct plan" do
      expect(subject.plan).to be_a(ProPlan)
    end

    it "has the correct key" do
      expect(subject.key).to eq :pro
    end
  end

  describe ".all" do
    let(:user) { double("user") }
    subject { TestTiers.all(user:) }

    it "returns all tiers" do
      expect(subject.map(&:key)).to eq [:free, :pro, :enterprise]
    end
  end

  describe ".first" do
    let(:user) { double("user") }
    subject { TestTiers.first(user:) }

    it "returns the first tier" do
      expect(subject.key).to eq :free
    end
  end
end

RSpec.describe Superfeature::Tier do
  before do
    stub_const("FreePlan", Class.new(Superfeature::Plan) do
      def initialize(user) = @user = user
      def name = "Free"
      def price = 0
      def description = "Free tier"
    end)
    stub_const("ProPlan", Class.new(Superfeature::Plan) do
      def initialize(user) = @user = user
      def name = "Pro"
      def price = 10
      def description = "Pro tier"
    end)
    stub_const("EnterprisePlan", Class.new(Superfeature::Plan) do
      def initialize(user) = @user = user
      def name = "Enterprise"
      def price = 100
      def description = "Enterprise tier"
    end)

    stub_const("TestTiers", Class.new(Superfeature::Tiers) do
      tier FreePlan, as: :free
      tier ProPlan, as: :pro
      tier EnterprisePlan, as: :enterprise
    end)
  end

  let(:user) { double("user") }

  describe "#key" do
    it "returns the tier key" do
      tier = TestTiers.build(:pro, user:)
      expect(tier.key).to eq :pro
    end
  end

  describe "#to_param" do
    it "returns the key as a string" do
      tier = TestTiers.build(:pro, user:)
      expect(tier.to_param).to eq "pro"
    end
  end

  describe "#next" do
    it "returns the next tier" do
      tier = TestTiers.build(:pro, user:)
      expect(tier.next).to be_a(Superfeature::Tier)
      expect(tier.next.key).to eq :enterprise
    end

    it "returns nil for the last tier" do
      tier = TestTiers.build(:enterprise, user:)
      expect(tier.next).to be_nil
    end
  end

  describe "#previous" do
    it "returns the previous tier" do
      tier = TestTiers.build(:pro, user:)
      expect(tier.previous).to be_a(Superfeature::Tier)
      expect(tier.previous.key).to eq :free
    end

    it "returns nil for the first tier" do
      tier = TestTiers.build(:free, user:)
      expect(tier.previous).to be_nil
    end
  end

  describe "delegation" do
    it "delegates name to plan" do
      tier = TestTiers.build(:pro, user:)
      expect(tier.name).to eq "Pro"
    end

    it "delegates price to plan" do
      tier = TestTiers.build(:pro, user:)
      expect(tier.price).to eq 10
    end

    it "delegates description to plan" do
      tier = TestTiers.build(:pro, user:)
      expect(tier.description).to eq "Pro tier"
    end
  end
end
