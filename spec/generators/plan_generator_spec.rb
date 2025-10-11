require 'rails_helper'
require 'generators/superfeature/plan/plan_generator'

RSpec.describe Superfeature::Generators::PlanGenerator, type: :generator do
  include FileUtils

  let(:destination) { File.expand_path("../../tmp/generator_test", __dir__) }

  before do
    rm_rf(destination)
    mkdir_p(destination)
  end

  after do
    rm_rf(destination)
  end

  def run_generator(args)
    described_class.start(args, destination_root: destination)
  end

  context "with simple plan name" do
    it "creates plan file with correct name" do
      run_generator(%w[Enterprise])
      expect(File.exist?(File.join(destination, "app/plans/enterprise_plan.rb"))).to be true
    end

    it "creates correct class name" do
      run_generator(%w[Enterprise])
      content = File.read(File.join(destination, "app/plans/enterprise_plan.rb"))
      expect(content).to include("class EnterprisePlan < ApplicationPlan")
    end

    it "does not create EnterprisePlanPlan" do
      run_generator(%w[Enterprise])
      content = File.read(File.join(destination, "app/plans/enterprise_plan.rb"))
      expect(content).not_to include("EnterprisePlanPlan")
    end
  end

  context "with plan name already ending in Plan" do
    it "creates plan file without duplicate plan suffix" do
      run_generator(%w[EnterprisePlan])
      expect(File.exist?(File.join(destination, "app/plans/enterprise_plan.rb"))).to be true
    end

    it "does not create PlanPlan" do
      run_generator(%w[EnterprisePlan])
      content = File.read(File.join(destination, "app/plans/enterprise_plan.rb"))
      expect(content).to include("class EnterprisePlan < ApplicationPlan")
      expect(content).not_to include("PlanPlan")
    end
  end

  context "with underscored name" do
    it "creates plan file" do
      run_generator(%w[pro_tier])
      expect(File.exist?(File.join(destination, "app/plans/pro_tier_plan.rb"))).to be true
    end

    it "creates correct class name" do
      run_generator(%w[pro_tier])
      content = File.read(File.join(destination, "app/plans/pro_tier_plan.rb"))
      expect(content).to include("class ProTierPlan < ApplicationPlan")
    end
  end

  it "includes example comments" do
    run_generator(%w[Premium])
    content = File.read(File.join(destination, "app/plans/premium_plan.rb"))
    expect(content).to include("# Example:")
    expect(content).to include("ApplicationPlan")
  end
end