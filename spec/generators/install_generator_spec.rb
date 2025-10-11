require 'rails_helper'
require 'generators/superfeature/install/install_generator'

RSpec.describe Superfeature::Generators::InstallGenerator, type: :generator do
  include FileUtils

  let(:destination) { File.expand_path("../../tmp/generator_test", __dir__) }

  before do
    rm_rf(destination)
    mkdir_p(destination)
  end

  after do
    rm_rf(destination)
  end

  def run_generator
    described_class.start([], destination_root: destination)
  end

  it "creates app/plans directory" do
    run_generator
    expect(File.directory?(File.join(destination, "app/plans"))).to be true
  end

  it "creates application_plan.rb" do
    run_generator
    expect(File.exist?(File.join(destination, "app/plans/application_plan.rb"))).to be true
  end

  it "creates ApplicationPlan class" do
    run_generator
    content = File.read(File.join(destination, "app/plans/application_plan.rb"))
    expect(content).to include("class ApplicationPlan < Superfeature::Plan")
  end

  it "includes example comments" do
    run_generator
    content = File.read(File.join(destination, "app/plans/application_plan.rb"))
    expect(content).to include("# Hard limit")
    expect(content).to include("# Soft limit")
    expect(content).to include("# Unlimited")
    expect(content).to include("# Boolean feature")
  end
end