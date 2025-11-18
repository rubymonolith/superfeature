require 'rails_helper'

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
    end

    describe '#discount' do
      it 'returns a new Price with discount applied' do
        price = Price.new(49.99).discount(20.00)
        expect(price.amount).to eq(29.99)
      end

      it 'preserves the original price' do
        price = Price.new(49.99).discount(20.00)
        expect(price.original.amount).to eq(49.99)
      end

      it 'does not modify the original Price object' do
        original = Price.new(49.99)
        discounted = original.discount(20.00)
        expect(original.amount).to eq(49.99)
        expect(discounted.amount).to eq(29.99)
      end

      it 'handles zero discount' do
        price = Price.new(100.0).discount(0)
        expect(price.amount).to eq(100.0)
      end

      it 'does not allow negative prices' do
        price = Price.new(49.99).discount(60.00)
        expect(price.amount).to eq(0)
      end

      it 'converts discount to float' do
        price = Price.new(50).discount("10")
        expect(price.amount).to eq(40.0)
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

      it 'rounds to 2 decimal places' do
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
    end

    describe '#discount_amount' do
      it 'returns the dollar amount discounted' do
        price = Price.new(49.99).discount(20.00)
        expect(price.discount_amount).to eq(20.00)
      end

      it 'calculates from percentage discount' do
        price = Price.new(100.0).discount_percent(0.25)
        expect(price.discount_amount).to eq(25.0)
      end

      it 'returns 0 for non-discounted price' do
        price = Price.new(49.99)
        expect(price.discount_amount).to eq(0.0)
      end

      it 'rounds to 2 decimal places' do
        price = Price.new(99.99).discount_percent(0.333)
        expect(price.discount_amount).to eq(33.30)
      end
    end

    describe '#percent' do
      context 'with fixed discount' do
        it 'calculates the percentage' do
          price = Price.new(100.0).discount(25.0)
          expect(price.percent).to eq(0.25)
        end

        it 'calculates 50% discount' do
          price = Price.new(100.0).discount(50.0)
          expect(price.percent).to eq(0.5)
        end

        it 'calculates 20% discount' do
          price = Price.new(50.0).discount(10.0)
          expect(price.percent).to eq(0.2)
        end

        it 'rounds to 4 decimal places' do
          price = Price.new(99.99).discount(33.33)
          expect(price.percent).to eq(0.3333)
        end
      end

      context 'with percentage discount' do
        it 'returns the applied percentage' do
          price = Price.new(100.0).discount_percent(0.25)
          expect(price.percent).to eq(0.25)
        end
      end

      context 'without discount' do
        it 'returns 0.0' do
          price = Price.new(49.99)
          expect(price.percent).to eq(0.0)
        end
      end

      context 'with zero original price' do
        it 'returns 0.0 to avoid division by zero' do
          price = Price.new(0).discount(0)
          expect(price.percent).to eq(0.0)
        end
      end
    end

    describe '#savings' do
      it 'returns the same as discount_amount' do
        price = Price.new(49.99).discount(20.00)
        expect(price.savings).to eq(price.discount_amount)
        expect(price.savings).to eq(20.00)
      end

      it 'returns 0 for non-discounted price' do
        price = Price.new(49.99)
        expect(price.savings).to eq(0.0)
      end
    end

    describe '#discounted?' do
      it 'returns true when discount is applied' do
        price = Price.new(49.99).discount(20.00)
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
        price = Price.new(100.0).discount(0)
        expect(price.discounted?).to be true
      end
    end

    describe '#full_price' do
      it 'returns the original amount when discounted' do
        price = Price.new(49.99).discount(20.00)
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

    describe '#to_f' do
      it 'returns the amount as a float' do
        price = Price.new(49.99)
        expect(price.to_f).to eq(49.99)
        expect(price.to_f).to be_a(Float)
      end

      it 'returns discounted amount' do
        price = Price.new(49.99).discount(20.00)
        expect(price.to_f).to eq(29.99)
      end
    end

    describe '#to_s' do
      it 'returns the amount as a string' do
        price = Price.new(49.99)
        expect(price.to_s).to eq("49.99")
      end

      it 'returns discounted amount' do
        price = Price.new(49.99).discount(20.00)
        expect(price.to_s).to eq("29.99")
      end
    end

    describe 'chaining examples' do
      it 'supports the main use case' do
        price = Price.new(49.99).discount(20.00)
        
        expect(price.amount).to eq(29.99)
        expect(price.original.amount).to eq(49.99)
        expect(price.discount_amount).to eq(20.00)
      end

      it 'supports percentage discount chaining' do
        price = Price.new(100.0).discount_percent(0.25)
        
        expect(price.amount).to eq(75.0)
        expect(price.original.amount).to eq(100.0)
        expect(price.percent).to eq(0.25)
      end

      it 'allows multiple discounts' do
        price = Price.new(100.0)
          .discount(10.0)
          .discount(5.0)
        
        # First discount: 100 - 10 = 90
        # Second discount: 90 - 5 = 85
        expect(price.amount).to eq(85.0)
        # Original should be the first price in the chain
        expect(price.original.amount).to eq(90.0)
        expect(price.original.original.amount).to eq(100.0)
      end
    end

    describe 'rounding precision' do
      it 'has configurable amount precision constant' do
        expect(Price::AMOUNT_PRECISION).to eq(2)
      end

      it 'has configurable percent precision constant' do
        expect(Price::PERCENT_PRECISION).to eq(4)
      end

      it 'rounds amounts to AMOUNT_PRECISION decimal places' do
        price = Price.new(100.0).discount_percent(0.333)
        # 100 * 0.333 = 33.3, so 100 - 33.3 = 66.7 rounded to 2 decimals = 66.70
        expect(price.amount).to eq(66.7)
      end

      it 'rounds percentages to PERCENT_PRECISION decimal places' do
        price = Price.new(99.99).discount(33.33)
        # (33.33 / 99.99) = 0.333333... rounded to 4 decimals = 0.3333
        expect(price.percent).to eq(0.3333)
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
  end
end