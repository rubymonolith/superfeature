require 'rails_helper'

RSpec.describe "Superfeature::Price() convenience method" do
  it 'creates a Price via module method' do
    price = Superfeature::Price(100)
    expect(price).to be_a(Superfeature::Price)
    expect(price.amount).to eq(100.0)
  end

  it 'passes options through' do
    price = Superfeature::Price(100, amount_precision: 3)
    expect(price.amount_precision).to eq(3)
  end

  it 'works when included' do
    klass = Class.new { include Superfeature }
    obj = klass.new
    price = obj.Price(50)
    expect(price).to be_a(Superfeature::Price)
    expect(price.amount).to eq(50.0)
  end
end

module Superfeature
  RSpec.describe Price do
    describe '#initialize' do
      it 'creates a price with an amount' do
        price = Price.new(49.99)
        expect(price.amount).to eq(49.99)
      end

      it 'converts string to float' do
        price = Price.new("49.99")
        expect(price.amount).to eq(49.99)
      end

      it 'converts integer to float' do
        price = Price.new(50)
        expect(price.amount).to eq(50.0)
      end

      it 'has no original by default' do
        price = Price.new(49.99)
        expect(price.original).to be_nil
      end

      it 'uses default amount precision' do
        price = Price.new(49.99)
        expect(price.amount_precision).to eq(2)
      end

      it 'uses default percent precision' do
        price = Price.new(49.99)
        expect(price.percent_precision).to eq(4)
      end

      it 'accepts custom amount precision' do
        price = Price.new(49.99, amount_precision: 3)
        expect(price.amount_precision).to eq(3)
      end

      it 'accepts custom percent precision' do
        price = Price.new(49.99, percent_precision: 6)
        expect(price.percent_precision).to eq(6)
      end
    end

    describe '#discount' do
      context 'with numeric value' do
        it 'treats numeric as fixed dollar discount' do
          price = Price.new(100.0).discount(20)
          expect(price.amount).to eq(80.0)
        end

        it 'treats decimal as cents, not percent' do
          price = Price.new(100.0).discount(0.80)
          expect(price.amount).to eq(99.2)
        end
      end

      context 'with percent string' do
        it 'parses "25%" as 25% off' do
          price = Price.new(100.0).discount("25%")
          expect(price.amount).to eq(75.0)
        end

        it 'parses "50%" as 50% off' do
          price = Price.new(100.0).discount("50%")
          expect(price.amount).to eq(50.0)
        end

        it 'parses "10.5%" as 10.5% off' do
          price = Price.new(100.0).discount("10.5%")
          expect(price.amount).to eq(89.5)
        end
      end

      context 'with dollar string' do
        it 'parses "$20" as $20 off' do
          price = Price.new(100.0).discount("$20")
          expect(price.amount).to eq(80.0)
        end

        it 'parses "20" as $20 off' do
          price = Price.new(100.0).discount("20")
          expect(price.amount).to eq(80.0)
        end

        it 'parses "$19.99" as $19.99 off' do
          price = Price.new(100.0).discount("$19.99")
          expect(price.amount).to eq(80.01)
        end
      end

      context 'with invalid input' do
        it 'raises ArgumentError for invalid format' do
          expect { Price.new(100.0).discount("invalid") }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#discount_fixed' do
      it 'returns a new Price with discount applied' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.amount).to eq(29.99)
      end

      it 'preserves the original price' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.original.amount).to eq(49.99)
      end

      it 'does not modify the original Price object' do
        original = Price.new(49.99)
        discounted = original.discount_fixed(20.00)
        expect(original.amount).to eq(49.99)
        expect(discounted.amount).to eq(29.99)
      end

      it 'handles zero discount' do
        price = Price.new(100.0).discount_fixed(0)
        expect(price.amount).to eq(100.0)
      end

      it 'does not allow negative prices' do
        price = Price.new(49.99).discount_fixed(60.00)
        expect(price.amount).to eq(0)
      end

      it 'converts discount to float' do
        price = Price.new(50).discount_fixed("10")
        expect(price.amount).to eq(40.0)
      end

      it 'preserves precision settings' do
        price = Price.new(100.0, amount_precision: 3).discount_fixed(20.0)
        expect(price.amount_precision).to eq(3)
      end
    end

    describe '#to' do
      it 'sets the price to the specified amount' do
        price = Price.new(300).to(200)
        expect(price.amount).to eq(200.0)
      end

      it 'is equivalent to discount_fixed with the difference' do
        price_to = Price.new(300).to(200)
        price_fixed = Price.new(300).discount_fixed(100)
        expect(price_to.amount).to eq(price_fixed.amount)
      end

      it 'preserves the original price' do
        price = Price.new(300).to(200)
        expect(price.original.amount).to eq(300.0)
      end

      it 'calculates the correct fixed_discount' do
        price = Price.new(300).to(200)
        expect(price.fixed_discount).to eq(100.0)
      end

      it 'calculates the correct percent_discount' do
        price = Price.new(300).to(200)
        expect(price.percent_discount).to be_within(0.0001).of(0.3333)
      end

      it 'returns original price when target is higher' do
        price = Price.new(100).to(150)
        expect(price.amount).to eq(100.0)
      end

      it 'converts target amount to float' do
        price = Price.new(300).to("200")
        expect(price.amount).to eq(200.0)
      end

      it 'preserves precision settings' do
        price = Price.new(300.0, amount_precision: 3).to(200.0)
        expect(price.amount_precision).to eq(3)
      end

      it 'works in discount chains' do
        price = Price.new(300).to(250).discount_fixed(10)
        expect(price.amount).to eq(240.0)
      end
    end

    describe '#discount_percent' do
      it 'applies percentage discount' do
        price = Price.new(100.0).discount_percent(0.25)
        expect(price.amount).to eq(75.0)
      end

      it 'preserves the original price' do
        price = Price.new(100.0).discount_percent(0.25)
        expect(price.original.amount).to eq(100.0)
      end

      it 'handles 50% discount' do
        price = Price.new(100.0).discount_percent(0.5)
        expect(price.amount).to eq(50.0)
      end

      it 'handles 10% discount' do
        price = Price.new(100.0).discount_percent(0.1)
        expect(price.amount).to eq(90.0)
      end

      it 'rounds to configured precision' do
        price = Price.new(99.99).discount_percent(0.333)
        expect(price.amount).to eq(66.69)
      end

      it 'handles 100% discount' do
        price = Price.new(100.0).discount_percent(1.0)
        expect(price.amount).to eq(0.0)
      end

      it 'converts percent to float' do
        price = Price.new(100).discount_percent("0.25")
        expect(price.amount).to eq(75.0)
      end

      it 'preserves precision settings' do
        price = Price.new(100.0, percent_precision: 6).discount_percent(0.25)
        expect(price.percent_precision).to eq(6)
      end
    end

    describe '#fixed_discount' do
      it 'returns the dollar amount discounted' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.fixed_discount).to eq(20.00)
      end

      it 'calculates from percentage discount' do
        price = Price.new(100.0).discount_percent(0.25)
        expect(price.fixed_discount).to eq(25.0)
      end

      it 'returns 0 for non-discounted price' do
        price = Price.new(49.99)
        expect(price.fixed_discount).to eq(0.0)
      end

      it 'rounds to configured precision' do
        price = Price.new(99.99, amount_precision: 3).discount_percent(0.333)
        expect(price.fixed_discount).to eq(33.297)
      end
    end

    describe '#percent_discount' do
      context 'with fixed discount' do
        it 'calculates the percentage' do
          price = Price.new(100.0).discount_fixed(25.0)
          expect(price.percent_discount).to eq(0.25)
        end

        it 'calculates 50% discount' do
          price = Price.new(100.0).discount_fixed(50.0)
          expect(price.percent_discount).to eq(0.5)
        end

        it 'calculates 20% discount' do
          price = Price.new(50.0).discount_fixed(10.0)
          expect(price.percent_discount).to eq(0.2)
        end

        it 'rounds to configured precision' do
          price = Price.new(99.99, percent_precision: 6).discount_fixed(33.33)
          expect(price.percent_discount).to eq(0.333333)
        end
      end

      context 'with percentage discount' do
        it 'returns the applied percentage' do
          price = Price.new(100.0).discount_percent(0.25)
          expect(price.percent_discount).to eq(0.25)
        end
      end

      context 'without discount' do
        it 'returns 0.0' do
          price = Price.new(49.99)
          expect(price.percent_discount).to eq(0.0)
        end
      end

      context 'with zero original price' do
        it 'returns 0.0 to avoid division by zero' do
          price = Price.new(0).discount_fixed(0)
          expect(price.percent_discount).to eq(0.0)
        end
      end
    end

    describe '#discounted?' do
      it 'returns true when discount is applied' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.discounted?).to be true
      end

      it 'returns true when percentage discount is applied' do
        price = Price.new(100.0).discount_percent(0.25)
        expect(price.discounted?).to be true
      end

      it 'returns false when no discount is applied' do
        price = Price.new(49.99)
        expect(price.discounted?).to be false
      end

      it 'returns true even with zero discount' do
        price = Price.new(100.0).discount_fixed(0)
        expect(price.discounted?).to be true
      end
    end

    describe '#full_price' do
      it 'returns the original amount when discounted' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.full_price).to eq(49.99)
      end

      it 'returns the current amount when not discounted' do
        price = Price.new(49.99)
        expect(price.full_price).to eq(49.99)
      end

      it 'works with percentage discount' do
        price = Price.new(100.0).discount_percent(0.25)
        expect(price.full_price).to eq(100.0)
      end
    end

    describe '#to_formatted_s' do
      it 'formats with default precision' do
        price = Price.new(49.99)
        expect(price.to_formatted_s).to eq("49.99")
      end

      it 'formats with custom precision' do
        price = Price.new(49.999, amount_precision: 3)
        expect(price.to_formatted_s).to eq("49.999")
      end

      it 'pads zeros to match precision' do
        price = Price.new(50)
        expect(price.to_formatted_s).to eq("50.00")
      end

      it 'formats discounted price' do
        price = Price.new(100.0).discount_fixed(20.0)
        expect(price.to_formatted_s).to eq("80.00")
      end
    end

    describe '#to_f' do
      it 'returns the amount as a float' do
        price = Price.new(49.99)
        expect(price.to_f).to eq(49.99)
        expect(price.to_f).to be_a(Float)
      end

      it 'returns discounted amount' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.to_f).to eq(29.99)
      end
    end

    describe '#to_s' do
      it 'returns the amount as a string' do
        price = Price.new(49.99)
        expect(price.to_s).to eq("49.99")
      end

      it 'returns discounted amount' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.to_s).to eq("29.99")
      end
    end

    describe 'chaining discounts' do
      it 'supports the main use case' do
        price = Price.new(49.99).discount_fixed(20.00)

        expect(price.amount).to eq(29.99)
        expect(price.original.amount).to eq(49.99)
        expect(price.fixed_discount).to eq(20.00)
      end

      it 'supports percentage discount chaining' do
        price = Price.new(100.0).discount_percent(0.25)

        expect(price.amount).to eq(75.0)
        expect(price.original.amount).to eq(100.0)
        expect(price.percent_discount).to eq(0.25)
      end

      it 'allows multiple discounts' do
        price = Price.new(100.0)
          .discount_fixed(10.0)
          .discount_fixed(5.0)

        # First discount: 100 - 10 = 90
        # Second discount: 90 - 5 = 85
        expect(price.amount).to eq(85.0)
        expect(price.original.amount).to eq(90.0)
        expect(price.original.original.amount).to eq(100.0)
      end

      it 'allows mixing discount types' do
        price = Price.new(100.0)
          .discount_percent(0.10)
          .discount_fixed(5.0)

        # First: 100 - 10% = 90
        # Second: 90 - 5 = 85
        expect(price.amount).to eq(85.0)
      end

      it 'preserves precision through chain' do
        price = Price.new(100.0, amount_precision: 3)
          .discount_fixed(10.0)
          .discount_fixed(5.0)

        expect(price.amount_precision).to eq(3)
        expect(price.original.amount_precision).to eq(3)
      end
    end

    describe 'precision configuration' do
      it 'has configurable default amount precision constant' do
        expect(Price::DEFAULT_AMOUNT_PRECISION).to eq(2)
      end

      it 'has configurable default percent precision constant' do
        expect(Price::DEFAULT_PERCENT_PRECISION).to eq(4)
      end

      it 'uses custom amount precision for rounding' do
        price = Price.new(100.0, amount_precision: 3).discount_percent(0.3333)
        expect(price.amount).to eq(66.67)
      end

      it 'uses custom percent precision for rounding' do
        price = Price.new(99.99, percent_precision: 2).discount_fixed(33.33)
        expect(price.percent_discount).to eq(0.33)
      end
    end

    describe 'edge cases' do
      it 'handles very small amounts' do
        price = Price.new(0.01).discount_percent(0.5)
        expect(price.amount).to eq(0.01)
      end

      it 'handles large amounts' do
        price = Price.new(1_000_000.00).discount_percent(0.1)
        expect(price.amount).to eq(900_000.0)
      end

      it 'handles fractional percentages' do
        price = Price.new(100.0).discount_percent(0.155)
        expect(price.amount).to eq(84.5)
      end
    end

    describe '#discount_source' do
      it 'returns nil when no discount applied' do
        price = Price.new(100.0)
        expect(price.discount_source).to be_nil
      end

      it 'returns the string passed to discount' do
        price = Price.new(100.0).discount("25%")
        expect(price.discount_source).to eq("25%")
      end

      it 'returns the numeric value passed to discount' do
        price = Price.new(100.0).discount(20)
        expect(price.discount_source).to eq(20)
      end

      it 'returns the Discount object passed to discount' do
        discount = Discount::Percent.new(25)
        price = Price.new(100.0).discount(discount)
        expect(price.discount_source).to eq(discount)
      end

      it 'returns custom object passed to discount' do
        deal = Class.new do
          attr_reader :name

          def initialize(name, percent)
            @name = name
            @percent = percent
          end

          def to_discount
            Superfeature::Discount::Percent.new(@percent)
          end
        end.new("Launch Special", 25)

        price = Price.new(100.0).discount(deal)
        expect(price.discount_source).to eq(deal)
        expect(price.discount_source.name).to eq("Launch Special")
      end

      it 'tracks discount_source through chains' do
        price = Price.new(100.0)
          .discount("10%")
          .discount("$5")

        expect(price.discount_source).to eq("$5")
        expect(price.original.discount_source).to eq("10%")
      end
    end

    describe 'discount with Discount objects' do
      it 'accepts Discount::Fixed directly' do
        price = Price.new(100.0).discount(Discount::Fixed.new(20))
        expect(price.amount).to eq(80.0)
      end

      it 'accepts Discount::Percent directly' do
        price = Price.new(100.0).discount(Discount::Percent.new(25))
        expect(price.amount).to eq(75.0)
      end

      it 'accepts Discount::Bundle directly' do
        bundle = Discount::Bundle.new(
          Discount::Fixed.new(10),
          Discount::Percent.new(20)
        )
        price = Price.new(100.0).discount(bundle)
        # 100 - 10 = 90, then 90 * 0.8 = 72
        expect(price.amount).to eq(72.0)
      end
    end

    describe 'to_discount protocol' do
      it 'accepts any object responding to to_discount' do
        custom_discount = Class.new do
          def to_discount
            Superfeature::Discount::Percent.new(50)
          end
        end.new

        price = Price.new(100.0).discount(custom_discount)
        expect(price.amount).to eq(50.0)
      end

      it 'allows rich domain objects as discount sources' do
        promotion = Class.new do
          attr_reader :name, :percent_off

          def initialize(name:, percent_off:)
            @name = name
            @percent_off = percent_off
          end

          def to_discount
            Superfeature::Discount::Percent.new(@percent_off)
          end
        end.new(name: "Summer Sale", percent_off: 30)

        price = Price.new(100.0).discount(promotion)

        expect(price.amount).to eq(70.0)
        expect(price.discount_source).to eq(promotion)
        expect(price.discount_source.name).to eq("Summer Sale")
        expect(price.discount_source.percent_off).to eq(30)
      end
    end
  end
end
