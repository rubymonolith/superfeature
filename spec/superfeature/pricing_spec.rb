require 'rails_helper'

module Superfeature
  RSpec.describe Pricing do
    describe '#initialize' do
      context 'with full_price only' do
        it 'sets discount_price equal to full_price' do
          pricing = Pricing.new(full_price: 100.0)
          expect(pricing.full_price).to eq(100.0)
          expect(pricing.discount_price).to eq(100.0)
          expect(pricing.discount_percent).to eq(0.0)
        end
      end

      context 'with full_price and discount_price' do
        it 'calculates discount_percent from prices' do
          pricing = Pricing.new(full_price: 100.0, discount_price: 80.0)
          expect(pricing.full_price).to eq(100.0)
          expect(pricing.discount_price).to eq(80.0)
          expect(pricing.discount_percent).to eq(0.2)
        end

        it 'handles 50% discount correctly' do
          pricing = Pricing.new(full_price: 100.0, discount_price: 50.0)
          expect(pricing.discount_percent).to eq(0.5)
        end

        it 'handles 10% discount correctly' do
          pricing = Pricing.new(full_price: 99.99, discount_price: 89.99)
          expect(pricing.discount_percent).to eq(0.1)
        end
      end

      context 'with full_price and discount_percent' do
        it 'calculates discount_price from percent' do
          pricing = Pricing.new(full_price: 100.0, discount_percent: 0.2)
          expect(pricing.full_price).to eq(100.0)
          expect(pricing.discount_price).to eq(80.0)
          expect(pricing.discount_percent).to eq(0.2)
        end

        it 'handles 50% discount correctly' do
          pricing = Pricing.new(full_price: 100.0, discount_percent: 0.5)
          expect(pricing.discount_price).to eq(50.0)
        end

        it 'handles 25% discount correctly' do
          pricing = Pricing.new(full_price: 80.0, discount_percent: 0.25)
          expect(pricing.discount_price).to eq(60.0)
        end
      end

      context 'when both discount_price and discount_percent are provided' do
        it 'uses discount_price and recalculates percent' do
          pricing = Pricing.new(full_price: 100.0, discount_price: 75.0, discount_percent: 0.5)
          expect(pricing.discount_price).to eq(75.0)
          expect(pricing.discount_percent).to eq(0.25)
        end
      end

      context 'with string inputs' do
        it 'converts strings to floats' do
          pricing = Pricing.new(full_price: "100", discount_price: "80")
          expect(pricing.full_price).to eq(100.0)
          expect(pricing.discount_price).to eq(80.0)
          expect(pricing.discount_percent).to eq(0.2)
        end
      end

      context 'with integer inputs' do
        it 'converts integers to floats' do
          pricing = Pricing.new(full_price: 100, discount_percent: 0.2)
          expect(pricing.full_price).to eq(100.0)
          expect(pricing.discount_price).to eq(80.0)
          expect(pricing.discount_percent).to eq(0.2)
        end
      end
    end

    describe '#savings' do
      it 'returns the amount saved with discount_price' do
        pricing = Pricing.new(full_price: 100.0, discount_price: 80.0)
        expect(pricing.savings).to eq(20.0)
      end

      it 'returns the amount saved with discount_percent' do
        pricing = Pricing.new(full_price: 100.0, discount_percent: 0.3)
        expect(pricing.savings).to eq(30.0)
      end

      it 'returns 0 when no discount' do
        pricing = Pricing.new(full_price: 100.0)
        expect(pricing.savings).to eq(0.0)
      end
    end

    describe '#discounted?' do
      it 'returns true when there is a discount' do
        pricing = Pricing.new(full_price: 100.0, discount_price: 80.0)
        expect(pricing.discounted?).to be true
      end

      it 'returns false when there is no discount' do
        pricing = Pricing.new(full_price: 100.0)
        expect(pricing.discounted?).to be false
      end

      it 'returns false when discount_price equals full_price' do
        pricing = Pricing.new(full_price: 100.0, discount_price: 100.0)
        expect(pricing.discounted?).to be false
      end
    end

    describe 'edge cases' do
      it 'handles zero full_price gracefully' do
        pricing = Pricing.new(full_price: 0, discount_price: 0)
        expect(pricing.discount_percent).to eq(0.0)
      end

      it 'handles 100% discount' do
        pricing = Pricing.new(full_price: 100.0, discount_percent: 1.0)
        expect(pricing.discount_price).to eq(0.0)
      end

      it 'handles fractional percentages' do
        pricing = Pricing.new(full_price: 100.0, discount_percent: 0.155)
        expect(pricing.discount_price).to eq(84.5)
      end
    end
  end
end