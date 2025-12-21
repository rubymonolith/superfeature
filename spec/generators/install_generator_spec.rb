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

  it "creates base.rb" do
    run_generator
    expect(File.exist?(File.join(destination, "app/plans/base.rb"))).to be true
  end

  it "creates Plans::Base class" do
    run_generator
    content = File.read(File.join(destination, "app/plans/base.rb"))
    expect(content).to include("class Base < Superfeature::Plan")
  end

  it "includes feature type comments" do
    run_generator
    content = File.read(File.join(destination, "app/plans/base.rb"))
    expect(content).to include("# Boolean features")
    expect(content).to include("# Hard limits")
    expect(content).to include("# Soft limits")
    expect(content).to include("# Unlimited")
  end

  it "creates features/base.rb with name and group" do
    run_generator
    content = File.read(File.join(destination, "app/plans/features/base.rb"))
    expect(content).to include("attr_reader :name, :group")
  end

  it "creates free.rb with next method" do
    run_generator
    content = File.read(File.join(destination, "app/plans/free.rb"))
    expect(content).to include("def next = plan(Paid)")
  end

  it "creates paid.rb with previous method" do
    run_generator
    content = File.read(File.join(destination, "app/plans/paid.rb"))
    expect(content).to include("def previous = plan(Free)")
  end

  it "creates free.rb and paid.rb plans" do
    run_generator
    expect(File.exist?(File.join(destination, "app/plans/free.rb"))).to be true
    expect(File.exist?(File.join(destination, "app/plans/paid.rb"))).to be true
  end
end
