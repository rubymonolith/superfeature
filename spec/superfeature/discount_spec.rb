require 'rails_helper'

module Superfeature
  RSpec.describe Discount do
    describe Discount::Fixed do
      it 'subtracts the fixed amount from price' do
        discount = Discount::Fixed.new(20)
        expect(discount.apply(100)).to eq(80)
      end

      it 'responds to to_discount returning self' do
        discount = Discount::Fixed.new(20)
        expect(discount.to_discount).to eq(discount)
      end

      it 'handles decimal amounts' do
        discount = Discount::Fixed.new(19.99)
        expect(discount.apply(100)).to eq(80.01)
      end

      it 'formats as integer string' do
        discount = Discount::Fixed.new(20)
        expect(discount.to_formatted_s).to eq("20")
      end

      it 'truncates decimal in formatted string' do
        discount = Discount::Fixed.new(19.99)
        expect(discount.to_formatted_s).to eq("19")
      end
    end

    describe Discount::Percent do
      it 'applies percentage discount' do
        discount = Discount::Percent.new(25)
        expect(discount.apply(100)).to eq(75)
      end

      it 'responds to to_discount returning self' do
        discount = Discount::Percent.new(25)
        expect(discount.to_discount).to eq(discount)
      end

      it 'handles 50% discount' do
        discount = Discount::Percent.new(50)
        expect(discount.apply(100)).to eq(50)
      end

      it 'handles 100% discount' do
        discount = Discount::Percent.new(100)
        expect(discount.apply(100)).to eq(0)
      end

      it 'accepts float percentages' do
        discount = Discount::Percent.new(10.5)
        expect(discount.apply(100)).to eq(89.5)
      end

      it 'formats as percentage string' do
        discount = Discount::Percent.new(50)
        expect(discount.to_formatted_s).to eq("50%")
      end

      it 'truncates decimal in formatted string' do
        discount = Discount::Percent.new(10.5)
        expect(discount.to_formatted_s).to eq("10%")
      end
    end

    describe Discount::Bundle do
      it 'applies discounts in order' do
        bundle = Discount::Bundle.new(
          Discount::Fixed.new(10),
          Discount::Percent.new(20)
        )
        # 100 - 10 = 90, then 90 * 0.8 = 72
        expect(bundle.apply(100)).to eq(72)
      end

      it 'responds to to_discount returning self' do
        bundle = Discount::Bundle.new(Discount::Fixed.new(10))
        expect(bundle.to_discount).to eq(bundle)
      end

      it 'handles empty bundle' do
        bundle = Discount::Bundle.new
        expect(bundle.apply(100)).to eq(100)
      end

      it 'works with objects responding to to_discount' do
        custom_discount = Class.new do
          def to_discount
            Discount::Percent.new(10)
          end
        end.new

        bundle = Discount::Bundle.new(
          Discount::Fixed.new(10),
          custom_discount
        )
        # 100 - 10 = 90, then 90 * 0.9 = 81
        expect(bundle.apply(100)).to eq(81)
      end
    end

    describe 'convenience methods' do
      it 'Discount::Fixed() creates a Fixed discount' do
        discount = Discount::Fixed(20)
        expect(discount).to be_a(Discount::Fixed)
        expect(discount.amount).to eq(20)
      end

      it 'Discount::Percent() creates a Percent discount' do
        discount = Discount::Percent(25)
        expect(discount).to be_a(Discount::Percent)
        expect(discount.percent).to eq(25)
      end

      it 'Discount::Bundle() creates a Bundle discount with splat args' do
        bundle = Discount::Bundle(
          Discount::Fixed(5),
          Discount::Percent(10)
        )
        expect(bundle).to be_a(Discount::Bundle)
        expect(bundle.discounts.size).to eq(2)
      end
    end
  end
end

RSpec.describe "Superfeature top-level discount methods" do
  it 'Fixed() creates a Fixed discount' do
    discount = Superfeature::Fixed(20)
    expect(discount).to be_a(Superfeature::Discount::Fixed)
    expect(discount.amount).to eq(20)
  end

  it 'Percent() creates a Percent discount' do
    discount = Superfeature::Percent(25)
    expect(discount).to be_a(Superfeature::Discount::Percent)
    expect(discount.percent).to eq(25)
  end

  it 'Bundle() creates a Bundle discount' do
    bundle = Superfeature::Bundle(
      Superfeature::Fixed(5),
      Superfeature::Percent(10)
    )
    expect(bundle).to be_a(Superfeature::Discount::Bundle)
    expect(bundle.discounts.size).to eq(2)
  end

  it 'works when included in a class' do
    klass = Class.new { include Superfeature }
    obj = klass.new

    discount = obj.Percent(25)
    expect(discount).to be_a(Superfeature::Discount::Percent)
  end
end
