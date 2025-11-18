require 'rails_helper'

RSpec.describe Superfeature do
  describe ".plan" do
    subject(:plan_klass) do
      described_class.plan do
        def api_calls
          hard_limit quantity: 50, maximum: 100
        end
      end
    end

    it { is_expected.to be_a(Class) }
    it { is_expected.to be < Superfeature::Plan }

    describe "instance" do
      subject { plan_klass.new }
      it { is_expected.to respond_to(:api_calls) }
    end
  end
end