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
    it "creates plan file" do
      run_generator(%w[Enterprise])
      expect(File.exist?(File.join(destination, "app/plans/enterprise.rb"))).to be true
    end

    it "creates correct class name" do
      run_generator(%w[Enterprise])
      content = File.read(File.join(destination, "app/plans/enterprise.rb"))
      expect(content).to include("class Enterprise < Base")
    end
  end

  context "with plan name already ending in Plan" do
    it "strips Plan suffix from file name" do
      run_generator(%w[EnterprisePlan])
      expect(File.exist?(File.join(destination, "app/plans/enterprise.rb"))).to be true
    end

    it "strips Plan suffix from class name" do
      run_generator(%w[EnterprisePlan])
      content = File.read(File.join(destination, "app/plans/enterprise.rb"))
      expect(content).to include("class Enterprise < Base")
      expect(content).not_to include("EnterprisePlan")
    end
  end

  context "with underscored name" do
    it "creates plan file" do
      run_generator(%w[pro_tier])
      expect(File.exist?(File.join(destination, "app/plans/pro_tier.rb"))).to be true
    end

    it "creates correct class name" do
      run_generator(%w[pro_tier])
      content = File.read(File.join(destination, "app/plans/pro_tier.rb"))
      expect(content).to include("class ProTier < Base")
    end
  end

  it "includes override example comment" do
    run_generator(%w[Premium])
    content = File.read(File.join(destination, "app/plans/premium.rb"))
    expect(content).to include("# Override features from Base")
    expect(content).to include("super.enable")
  end
end
