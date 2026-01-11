require 'rails_helper'

RSpec.describe "Superfeature::Price() convenience method" do
  it 'creates a Price via module method' do
    price = Superfeature::Price(100)
    expect(price).to be_a(Superfeature::Price)
    expect(price.amount).to eq(100.0)
  end

  it 'passes options through' do
    price = Superfeature::Price(100, range: 0..200)
    expect(price.range).to eq(0..200)
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

      it 'has no previous by default' do
        price = Price.new(49.99)
        expect(price.previous).to be_nil
      end

      it 'returns itself as original when no discounts' do
        price = Price.new(49.99)
        expect(price.original).to eq(price)
      end

      it 'uses default range of 0..' do
        price = Price.new(49.99)
        expect(price.range).to eq(0..)
      end

      it 'clamps negative amounts to 0 by default' do
        price = Price.new(-10)
        expect(price.amount).to eq(0.0)
      end

      it 'accepts custom range' do
        price = Price.new(50, range: 10..100)
        expect(price.range).to eq(10..100)
      end

      it 'clamps to custom range' do
        expect(Price.new(5, range: 10..100).amount).to eq(10.0)
        expect(Price.new(150, range: 10..100).amount).to eq(100.0)
      end

      it 'allows nil range for no clamping' do
        price = Price.new(-50, range: nil)
        expect(price.amount).to eq(-50.0)
      end
    end

    describe '#apply_discount' do
      context 'with numeric value' do
        it 'treats numeric as fixed dollar discount' do
          price = Price.new(100.0).apply_discount(20)
          expect(price.amount).to eq(80.0)
        end

        it 'treats decimal as cents, not percent' do
          price = Price.new(100.0).apply_discount(0.80)
          expect(price.amount).to eq(99.2)
        end
      end

      context 'with percent string' do
        it 'parses "25%" as 25% off' do
          price = Price.new(100.0).apply_discount("25%")
          expect(price.amount).to eq(75.0)
        end

        it 'parses "50%" as 50% off' do
          price = Price.new(100.0).apply_discount("50%")
          expect(price.amount).to eq(50.0)
        end

        it 'parses "10.5%" as 10.5% off' do
          price = Price.new(100.0).apply_discount("10.5%")
          expect(price.amount).to eq(89.5)
        end
      end

      context 'with dollar string' do
        it 'parses "$20" as $20 off' do
          price = Price.new(100.0).apply_discount("$20")
          expect(price.amount).to eq(80.0)
        end

        it 'parses "20" as $20 off' do
          price = Price.new(100.0).apply_discount("20")
          expect(price.amount).to eq(80.0)
        end

        it 'parses "$19.99" as $19.99 off' do
          price = Price.new(100.0).apply_discount("$19.99")
          expect(price.amount).to eq(80.01)
        end
      end

      context 'with nil' do
        it 'returns the price unchanged' do
          price = Price.new(100.0).apply_discount(nil)
          expect(price.amount).to eq(100.0)
        end

        it 'does not mark the price as discounted' do
          price = Price.new(100.0).apply_discount(nil)
          expect(price.discounted?).to be false
        end

        it 'has no discount source' do
          price = Price.new(100.0).apply_discount(nil)
          expect(price.discount.source).to be_nil
        end
      end

      context 'with invalid input' do
        it 'raises ArgumentError for invalid format' do
          expect { Price.new(100.0).apply_discount("invalid") }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#discount_fixed' do
      it 'returns a new Price with discount applied' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.amount).to be_within(0.001).of(29.99)
      end

      it 'preserves the previous price' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.previous.amount).to eq(49.99)
      end

      it 'does not modify the original Price object' do
        original = Price.new(49.99)
        discounted = original.discount_fixed(20.00)
        expect(original.amount).to eq(49.99)
        expect(discounted.amount).to be_within(0.001).of(29.99)
      end

      it 'handles zero discount' do
        price = Price.new(100.0).discount_fixed(0)
        expect(price.amount).to eq(100.0)
      end

      it 'does not allow negative prices by default' do
        price = Price.new(49.99).discount_fixed(60.00)
        expect(price.amount).to eq(0)
      end

      it 'converts discount to float' do
        price = Price.new(50).discount_fixed("10")
        expect(price.amount).to eq(40.0)
      end

      it 'preserves range settings' do
        price = Price.new(100.0, range: 10..200).discount_fixed(20.0)
        expect(price.range).to eq(10..200)
      end
    end

    describe '#discount_to' do
      it 'sets the price to the specified amount' do
        price = Price.new(300).discount_to(200)
        expect(price.amount).to eq(200.0)
      end

      it 'is equivalent to discount_fixed with the difference' do
        price_to = Price.new(300).discount_to(200)
        price_fixed = Price.new(300).discount_fixed(100)
        expect(price_to.amount).to eq(price_fixed.amount)
      end

      it 'preserves the previous price' do
        price = Price.new(300).discount_to(200)
        expect(price.previous.amount).to eq(300.0)
      end

      it 'calculates the correct fixed discount' do
        price = Price.new(300).discount_to(200)
        expect(price.discount.fixed).to eq(100.0)
      end

      it 'calculates the correct percent discount' do
        price = Price.new(300).discount_to(200)
        expect(price.discount.percent).to be_within(0.01).of(33.33)
      end

      it 'returns original price when target is higher' do
        price = Price.new(100).discount_to(150)
        expect(price.amount).to eq(100.0)
      end

      it 'converts target amount to float' do
        price = Price.new(300).discount_to("200")
        expect(price.amount).to eq(200.0)
      end

      it 'preserves range settings' do
        price = Price.new(300.0, range: 0..500).discount_to(200.0)
        expect(price.range).to eq(0..500)
      end

      it 'works in discount chains' do
        price = Price.new(300).discount_to(250).discount_fixed(10)
        expect(price.amount).to eq(240.0)
      end
    end

    describe '#discount_percent' do
      it 'applies percentage discount' do
        price = Price.new(100.0).discount_percent(25)
        expect(price.amount).to eq(75.0)
      end

      it 'preserves the previous price' do
        price = Price.new(100.0).discount_percent(25)
        expect(price.previous.amount).to eq(100.0)
      end

      it 'handles 50% discount' do
        price = Price.new(100.0).discount_percent(50)
        expect(price.amount).to eq(50.0)
      end

      it 'handles 10% discount' do
        price = Price.new(100.0).discount_percent(10)
        expect(price.amount).to eq(90.0)
      end

      it 'handles fractional percentages' do
        price = Price.new(99.99).discount_percent(33.3)
        expect(price.amount).to be_within(0.01).of(66.69)
      end

      it 'handles 100% discount' do
        price = Price.new(100.0).discount_percent(100)
        expect(price.amount).to eq(0.0)
      end

      it 'converts percent to string' do
        price = Price.new(100).discount_percent("25")
        expect(price.amount).to eq(75.0)
      end

      it 'preserves range settings' do
        price = Price.new(100.0, range: 0..200).discount_percent(25)
        expect(price.range).to eq(0..200)
      end
    end

    describe '#charm' do
      it 'rounds to nearest ending by default' do
        price = Price.new(50).charm(9)
        expect(price.amount).to eq(49)
      end

      it 'rounds to nearest .99 ending' do
        price = Price.new(2.50).charm(0.99)
        expect(price.amount).to eq(2.99)
      end

      it 'preserves the previous price' do
        price = Price.new(50).charm(9)
        expect(price.previous.amount).to eq(50)
      end

      it 'marks the price as discounted' do
        price = Price.new(50).charm(9)
        expect(price.discounted?).to be true
      end
    end

    describe '#charm_up' do
      it 'rounds up to next ending in 9' do
        price = Price.new(50).charm_up(9)
        expect(price.amount).to eq(59)
      end

      it 'rounds up to next ending in .99' do
        price = Price.new(2.50).charm_up(0.99)
        expect(price.amount).to eq(2.99)
      end

      it 'stays at exact match' do
        price = Price.new(49).charm_up(9)
        expect(price.amount).to eq(49)
      end

      it 'preserves the previous price' do
        price = Price.new(50).charm_up(9)
        expect(price.previous.amount).to eq(50)
      end
    end

    describe '#charm_down' do
      it 'rounds down to previous ending in 9' do
        price = Price.new(50).charm_down(9)
        expect(price.amount).to eq(49)
      end

      it 'rounds down to previous ending in .99' do
        price = Price.new(2.50).charm_down(0.99)
        expect(price.amount).to eq(1.99)
      end

      it 'stays at exact match' do
        price = Price.new(49).charm_down(9)
        expect(price.amount).to eq(49)
      end

      it 'preserves the previous price' do
        price = Price.new(50).charm_down(9)
        expect(price.previous.amount).to eq(50)
      end
    end

    describe '#discount.fixed' do
      it 'returns the dollar amount discounted' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.discount.fixed).to eq(20.00)
      end

      it 'calculates from percentage discount' do
        price = Price.new(100.0).discount_percent(25)
        expect(price.discount.fixed).to eq(25.0)
      end

      it 'returns 0 for non-discounted price' do
        price = Price.new(49.99)
        expect(price.discount.fixed).to eq(0.0)
      end
    end

    describe '#discount.percent' do
      context 'with fixed discount' do
        it 'calculates the percentage' do
          price = Price.new(100.0).discount_fixed(25.0)
          expect(price.discount.percent).to eq(25.0)
        end

        it 'calculates 50% discount' do
          price = Price.new(100.0).discount_fixed(50.0)
          expect(price.discount.percent).to eq(50.0)
        end

        it 'calculates 20% discount' do
          price = Price.new(50.0).discount_fixed(10.0)
          expect(price.discount.percent).to eq(20.0)
        end
      end

      context 'with percentage discount' do
        it 'returns the applied percentage' do
          price = Price.new(100.0).discount_percent(25)
          expect(price.discount.percent).to eq(25.0)
        end
      end

      context 'without discount' do
        it 'returns 0.0' do
          price = Price.new(49.99)
          expect(price.discount.percent).to eq(0.0)
        end
      end

      context 'with zero original price' do
        it 'returns 0.0 to avoid division by zero' do
          price = Price.new(0).discount_fixed(0)
          expect(price.discount.percent).to eq(0.0)
        end
      end
    end

    describe '#discounted?' do
      it 'returns true when discount is applied' do
        price = Price.new(49.99).discount_fixed(20.00)
        expect(price.discounted?).to be true
      end

      it 'returns true when percentage discount is applied' do
        price = Price.new(100.0).discount_percent(25)
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
        price = Price.new(100.0).discount_percent(25)
        expect(price.full_price).to eq(100.0)
      end
    end

    describe '#to_formatted_s' do
      it 'formats with default decimals (2)' do
        price = Price.new(49.99)
        expect(price.to_formatted_s).to eq("49.99")
      end

      it 'formats with custom decimals' do
        price = Price.new(49.999)
        expect(price.to_formatted_s(decimals: 3)).to eq("49.999")
      end

      it 'pads zeros to match decimals' do
        price = Price.new(50)
        expect(price.to_formatted_s).to eq("50.00")
      end

      it 'formats discounted price' do
        price = Price.new(100.0).discount_fixed(20.0)
        expect(price.to_formatted_s).to eq("80.00")
      end

      it 'formats with no decimals' do
        price = Price.new(49.99)
        expect(price.to_formatted_s(decimals: 0)).to eq("50")
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
        expect(price.previous.amount).to eq(49.99)
        expect(price.discount.fixed).to eq(20.00)
      end

      it 'supports percentage discount chaining' do
        price = Price.new(100.0).discount_percent(25)

        expect(price.amount).to eq(75.0)
        expect(price.previous.amount).to eq(100.0)
        expect(price.discount.percent).to eq(25.0)
      end

      it 'allows multiple discounts' do
        price = Price.new(100.0)
          .discount_fixed(10.0)
          .discount_fixed(5.0)

        # First discount: 100 - 10 = 90
        # Second discount: 90 - 5 = 85
        expect(price.amount).to eq(85.0)
        expect(price.previous.amount).to eq(90.0)
        expect(price.previous.previous.amount).to eq(100.0)
        expect(price.original.amount).to eq(100.0)
      end

      it 'allows mixing discount types' do
        price = Price.new(100.0)
          .discount_percent(10)
          .discount_fixed(5.0)

        # First: 100 - 10% = 90
        # Second: 90 - 5 = 85
        expect(price.amount).to eq(85.0)
      end

      it 'preserves range through chain' do
        price = Price.new(100.0, range: 0..200)
          .discount_fixed(10.0)
          .discount_fixed(5.0)

        expect(price.range).to eq(0..200)
        expect(price.previous.range).to eq(0..200)
      end
    end

    describe 'comparison operators' do
      it 'compares two prices with ==' do
        expect(Price.new(100)).to eq(Price.new(100))
        expect(Price.new(100)).not_to eq(Price.new(50))
      end

      it 'compares price with numeric using ==' do
        expect(Price.new(100)).to eq(100)
        expect(Price.new(100)).to eq(100.0)
        expect(Price.new(100)).not_to eq(50)
      end

      it 'compares prices with <' do
        expect(Price.new(50)).to be < Price.new(100)
        expect(Price.new(100)).not_to be < Price.new(50)
      end

      it 'compares price with numeric using <' do
        expect(Price.new(50)).to be < 100
        expect(Price.new(100)).not_to be < 50
      end

      it 'compares prices with >' do
        expect(Price.new(100)).to be > Price.new(50)
        expect(Price.new(50)).not_to be > Price.new(100)
      end

      it 'compares price with numeric using >' do
        expect(Price.new(100)).to be > 50
        expect(Price.new(50)).not_to be > 100
      end

      it 'compares prices with <=' do
        expect(Price.new(50)).to be <= Price.new(100)
        expect(Price.new(100)).to be <= Price.new(100)
      end

      it 'compares prices with >=' do
        expect(Price.new(100)).to be >= Price.new(50)
        expect(Price.new(100)).to be >= Price.new(100)
      end

      it 'compares discounted prices' do
        full = Price.new(100)
        discounted = Price.new(100).apply_discount(Discount::Percent.new(20))
        expect(discounted).to be < full
        expect(discounted).to eq(80)
      end

      it 'returns nil when comparing with incompatible type' do
        expect(Price.new(100) <=> "string").to be_nil
      end
    end

    describe 'math operators' do
      describe '+' do
        it 'adds a numeric to a price' do
          expect((Price.new(100) + 20).amount).to eq(120.0)
        end

        it 'adds two prices together' do
          expect((Price.new(100) + Price.new(50)).amount).to eq(150.0)
        end

        it 'returns a new Price without discount info' do
          discounted = Price.new(100).apply_discount("20%")
          result = discounted + 10
          expect(result.amount).to eq(90.0)
          expect(result.discounted?).to be false
        end

        it 'preserves range settings' do
          result = Price.new(100, range: 0..200) + 10
          expect(result.range).to eq(0..200)
        end
      end

      describe '-' do
        it 'subtracts a numeric from a price' do
          expect((Price.new(100) - 20).amount).to eq(80.0)
        end

        it 'subtracts one price from another' do
          expect((Price.new(100) - Price.new(30)).amount).to eq(70.0)
        end
      end

      describe '*' do
        it 'multiplies a price by a numeric' do
          expect((Price.new(100) * 2).amount).to eq(200.0)
        end

        it 'multiplies two prices' do
          expect((Price.new(10) * Price.new(5)).amount).to eq(50.0)
        end
      end

      describe '/' do
        it 'divides a price by a numeric' do
          expect((Price.new(100) / 4).amount).to eq(25.0)
        end

        it 'divides one price by another' do
          expect((Price.new(100) / Price.new(4)).amount).to eq(25.0)
        end
      end

      it 'raises ArgumentError for incompatible types' do
        expect { Price.new(100) + "string" }.to raise_error(ArgumentError)
      end
    end

    describe 'unary minus' do
      it 'negates the price' do
        expect((-Price.new(100, range: nil)).amount).to eq(-100.0)
      end

      it 'works with negative prices' do
        expect((-Price.new(-50, range: nil)).amount).to eq(50.0)
      end

      it 'preserves range settings' do
        result = -Price.new(100, range: nil)
        expect(result.range).to be_nil
      end
    end

    describe '#abs' do
      it 'returns absolute value of positive price' do
        expect(Price.new(100).abs.amount).to eq(100.0)
      end

      it 'returns absolute value of negative price' do
        expect(Price.new(-100, range: nil).abs.amount).to eq(100.0)
      end

      it 'preserves range settings' do
        result = Price.new(-100, range: nil).abs
        expect(result.range).to be_nil
      end
    end

    describe '#zero? / #free?' do
      it 'returns true for zero price' do
        expect(Price.new(0)).to be_zero
        expect(Price.new(0)).to be_free
      end

      it 'returns false for non-zero price' do
        expect(Price.new(100)).not_to be_zero
        expect(Price.new(100)).not_to be_free
      end
    end

    describe '#positive? / #paid?' do
      it 'returns true for positive price' do
        expect(Price.new(100)).to be_positive
        expect(Price.new(100)).to be_paid
      end

      it 'returns false for zero' do
        expect(Price.new(0)).not_to be_positive
        expect(Price.new(0)).not_to be_paid
      end

      it 'returns false for negative price' do
        expect(Price.new(-100, range: nil)).not_to be_positive
        expect(Price.new(-100, range: nil)).not_to be_paid
      end
    end

    describe '#negative?' do
      it 'returns true for negative price' do
        expect(Price.new(-100, range: nil)).to be_negative
      end

      it 'returns false for zero' do
        expect(Price.new(0)).not_to be_negative
      end

      it 'returns false for positive price' do
        expect(Price.new(100)).not_to be_negative
      end
    end

    describe '#round' do
      it 'rounds to default precision' do
        expect(Price.new(19.999).round.amount).to eq(20.0)
      end

      it 'rounds to specified precision' do
        expect(Price.new(19.999).round(1).amount).to eq(20.0)
        expect(Price.new(19.456).round(2).amount).to eq(19.46)
      end

      it 'preserves range settings' do
        result = Price.new(19.999, range: 0..100).round
        expect(result.range).to eq(0..100)
      end
    end

    describe '#clamp' do
      it 'clamps price within range' do
        expect(Price.new(150, range: nil).clamp(0, 100).amount).to eq(100.0)
        expect(Price.new(-50, range: nil).clamp(0, 100).amount).to eq(0.0)
        expect(Price.new(50).clamp(0, 100).amount).to eq(50.0)
      end

      it 'accepts Price objects as bounds' do
        expect(Price.new(150, range: nil).clamp(Price.new(0), Price.new(100)).amount).to eq(100.0)
      end

      it 'preserves range settings' do
        result = Price.new(150, range: nil).clamp(0, 100)
        expect(result.range).to be_nil
      end
    end

    describe '#coerce' do
      it 'allows numeric + Price' do
        expect((10 + Price.new(5)).amount).to eq(15.0)
      end

      it 'allows numeric - Price' do
        expect((100 - Price.new(30)).amount).to eq(70.0)
      end

      it 'allows numeric * Price' do
        expect((3 * Price.new(10)).amount).to eq(30.0)
      end

      it 'allows numeric / Price' do
        expect((100 / Price.new(4)).amount).to eq(25.0)
      end

      it 'raises TypeError for incompatible types' do
        expect { Price.new(100).coerce("string") }.to raise_error(TypeError)
      end
    end

    describe 'edge cases' do
      it 'handles very small amounts' do
        price = Price.new(0.01).discount_percent(50)
        expect(price.amount).to eq(BigDecimal("0.005"))
      end

      it 'handles large amounts' do
        price = Price.new(1_000_000.00).discount_percent(10)
        expect(price.amount).to eq(900_000.0)
      end

      it 'handles fractional percentages' do
        price = Price.new(100.0).discount_percent(15.5)
        expect(price.amount).to eq(84.5)
      end
    end

    describe '#discount (accessor)' do
      it 'returns Discount::None when no discount applied' do
        price = Price.new(100.0)
        expect(price.discount).to be_a(Discount::None)
        expect(price.discount.none?).to be true
        expect(price.discount.to_formatted_s).to eq("")
        expect(price.discount.to_percent_s).to eq("0%")
        expect(price.discount.to_fixed_s).to eq("0.00")
      end

      it 'returns an Applied discount wrapping Discount::Percent' do
        price = Price.new(100.0).apply_discount("50%")
        expect(price.discount).to be_a(Discount::Applied)
        expect(price.discount.source).to be_a(Discount::Percent)
      end

      it 'returns an Applied discount wrapping Discount::Fixed' do
        price = Price.new(100.0).apply_discount("$20")
        expect(price.discount).to be_a(Discount::Applied)
        expect(price.discount.source).to be_a(Discount::Fixed)
      end

      it 'wraps the Discount object when passed directly' do
        discount = Discount::Percent.new(25)
        price = Price.new(100.0).apply_discount(discount)
        expect(price.discount.source).to eq(discount)
      end

      it 'allows formatted display via to_formatted_s' do
        price = Price.new(100.0).apply_discount("50%")
        expect(price.discount.to_formatted_s).to eq("50%")
      end

      it 'allows access to computed percent value' do
        price = Price.new(100.0).apply_discount("50%")
        expect(price.discount.percent).to eq(50.0)
      end

      it 'allows access to computed fixed value' do
        price = Price.new(100.0).apply_discount("50%")
        expect(price.discount.fixed).to eq(50.0)
      end

      it 'delegates amount to source for Fixed discounts' do
        price = Price.new(100.0).apply_discount(20)
        expect(price.discount.amount).to eq(20.0)
      end

      it 'formats as fixed string' do
        price = Price.new(19.0).apply_discount(Discount::Percent.new(20))
        expect(price.discount.to_fixed_s).to eq("3.80")
      end

      it 'formats as percent string' do
        price = Price.new(19.0).apply_discount(Discount::Percent.new(20))
        expect(price.discount.to_percent_s).to eq("20%")
      end

      it 'computes correct values for percent discount' do
        price = Price.new(19.0).apply_discount(Discount::Percent.new(20))
        expect(price.discount.fixed).to eq(3.8)
        expect(price.discount.percent).to eq(20.0)
      end

      it 'computes correct values for fixed discount' do
        price = Price.new(100.0).apply_discount(Discount::Fixed.new(20))
        expect(price.discount.fixed).to eq(20.0)
        expect(price.discount.percent).to eq(20.0)
      end
    end

    describe '#discount.source' do
      it 'returns nil when no discount applied' do
        price = Price.new(100.0)
        expect(price.discount.source).to be_nil
      end

      it 'returns the Discount object used' do
        price = Price.new(100.0).apply_discount("25%")
        expect(price.discount.source).to be_a(Discount::Percent)
      end

      it 'returns the Discount object for numeric discount' do
        price = Price.new(100.0).apply_discount(20)
        expect(price.discount.source).to be_a(Discount::Fixed)
      end

      it 'returns the Discount object passed directly' do
        discount = Discount::Percent.new(25)
        price = Price.new(100.0).apply_discount(discount)
        expect(price.discount.source).to eq(discount)
      end

      it 'works with custom objects responding to to_discount' do
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

        price = Price.new(100.0).apply_discount(deal)
        expect(price.discount.source).to be_a(Discount::Percent)
        expect(price.amount).to eq(75.0)
      end

      it 'tracks discount source through chains' do
        price = Price.new(100.0)
          .apply_discount("10%")
          .apply_discount("$5")

        expect(price.discount.source).to be_a(Discount::Fixed)
        expect(price.previous.discount.source).to be_a(Discount::Percent)
      end
    end

    describe 'discount with Discount objects' do
      it 'accepts Discount::Fixed directly' do
        price = Price.new(100.0).apply_discount(Discount::Fixed.new(20))
        expect(price.amount).to eq(80.0)
      end

      it 'accepts Discount::Percent directly' do
        price = Price.new(100.0).apply_discount(Discount::Percent.new(25))
        expect(price.amount).to eq(75.0)
      end

    end

    describe 'to_discount protocol' do
      it 'accepts any object responding to to_discount' do
        custom_discount = Class.new do
          def to_discount
            Superfeature::Discount::Percent.new(50)
          end
        end.new

        price = Price.new(100.0).apply_discount(custom_discount)
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

        price = Price.new(100.0).apply_discount(promotion)

        expect(price.amount).to eq(70.0)
        expect(price.discount.source).to be_a(Discount::Percent)
      end
    end

    describe '#itemization' do
      it 'returns an Itemization enumerable' do
        price = Price.new(100.0)
        expect(price.itemization).to be_a(Itemization)
      end
    end
  end

  RSpec.describe Itemization do
    describe '#original / #first' do
      it 'returns the original price before any discounts' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")
        itemization = Itemization.new(final)

        expect(itemization.original.amount).to eq(100.0)
        expect(itemization.first.amount).to eq(100.0)
      end

      it 'returns the price itself when no discounts applied' do
        price = Price.new(100)
        itemization = Itemization.new(price)

        expect(itemization.original.amount).to eq(100.0)
      end
    end

    describe '#final / #last' do
      it 'returns the final price after all discounts' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")
        itemization = Itemization.new(final)

        expect(itemization.final.amount).to eq(70.0)
        expect(itemization.last.amount).to eq(70.0)
      end

      it 'returns the price itself when no discounts applied' do
        price = Price.new(100)
        itemization = Itemization.new(price)

        expect(itemization.final.amount).to eq(100.0)
      end
    end

    describe '#each' do
      it 'yields prices in order from original to final' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")
        itemization = Itemization.new(final)

        amounts = itemization.map(&:amount)
        expect(amounts).to eq([100.0, 80.0, 70.0])
      end

      it 'returns an enumerator without a block' do
        price = Price.new(100)
        itemization = Itemization.new(price)

        expect(itemization.each).to be_a(Enumerator)
      end
    end

    describe '#to_a' do
      it 'returns array of prices from original to final' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")
        itemization = Itemization.new(final)

        expect(itemization.to_a.length).to eq(3)
        expect(itemization.to_a.first.amount).to eq(100.0)
        expect(itemization.to_a.last.amount).to eq(70.0)
      end
    end

    describe '#size / #count / #length' do
      it 'returns the number of prices in the chain' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")
        itemization = Itemization.new(final)

        expect(itemization.size).to eq(3)
        expect(itemization.count).to eq(3)
        expect(itemization.length).to eq(3)
      end

      it 'returns 1 for a single price with no discounts' do
        price = Price.new(100)
        itemization = Itemization.new(price)

        expect(itemization.size).to eq(1)
      end
    end

    describe 'Enumerable methods' do
      it 'supports select' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")
        itemization = Itemization.new(final)

        discounted = itemization.select(&:discounted?)
        expect(discounted.length).to eq(2)
      end

      it 'supports find' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")
        itemization = Itemization.new(final)

        found = itemization.find { |p| p.amount < 75 }
        expect(found.amount).to eq(70.0)
      end
    end

    describe 'via Price#itemization' do
      it 'provides access to the full chain' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")

        expect(final.itemization.original.amount).to eq(100.0)
        expect(final.itemization.final.amount).to eq(70.0)
        expect(final.itemization.count).to eq(3)
      end
    end

    describe 'original price itemization' do
      it 'returns just that price when no discounts' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")

        expect(final.original.itemization.count).to eq(1)
        expect(final.original.itemization.first.amount).to eq(100.0)
        expect(final.original.itemization.last.amount).to eq(100.0)
      end
    end
  end

  RSpec.describe Inspector do
    describe '#to_s' do
      it 'formats a simple discount chain' do
        final = Price.new(100).apply_discount("20%").apply_discount("$10")

        expected = <<~TEXT.chomp
          Original              100.00
          20% off               -20.00
                              --------
          Subtotal               80.00
          10.00 off             -10.00
                              --------
          FINAL                  70.00
        TEXT

        expect(Inspector.new(final.itemization).to_s).to eq(expected)
      end

      it 'formats a single price with no discounts' do
        price = Price.new(100)

        expected = <<~TEXT.chomp
          Original              100.00
                              --------
          FINAL                 100.00
        TEXT

        expect(Inspector.new(price.itemization).to_s).to eq(expected)
      end

      it 'formats prices with varying widths' do
        final = Price.new(1000).apply_discount("50%")

        expected = <<~TEXT.chomp
          Original              1000.00
          50% off               -500.00
                              ---------
          FINAL                  500.00
        TEXT

        expect(Inspector.new(final.itemization).to_s).to eq(expected)
      end

      it 'handles charm pricing discounts' do
        final = Price.new(100).discount_percent(50).charm_down(9)

        output = Inspector.new(final.itemization).to_s
        expect(output).to include("Original")
        expect(output).to include("FINAL")
        expect(output).to include("49.00")
      end

      it 'accepts custom label width' do
        final = Price.new(100).apply_discount("20%")

        output = Inspector.new(final.itemization, label_width: 15).to_s
        expect(output).to include("Original")
        expect(output).to include("FINAL")
      end
    end

    describe 'via Price#inspector' do
      it 'provides access to the inspector' do
        final = Price.new(100).apply_discount("20%")

        expect(final.inspector).to be_a(Inspector)
        expect(final.inspector.to_s).to include("Original")
        expect(final.inspector.to_s).to include("FINAL")
      end
    end

    describe 'via Price#pretty_print' do
      require 'pp'

      it 'outputs the inspector format' do
        final = Price.new(100).apply_discount("20%")

        output = PP.pp(final, +"")
        expect(output).to include("Original")
        expect(output).to include("FINAL")
      end
    end
  end
end
