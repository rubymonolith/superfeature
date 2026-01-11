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

    describe Discount::Charm do
      it 'returns a Charm object' do
        charm = Discount::Percent.new(50).charm(0.99)
        expect(charm).to be_a(Discount::Charm)
      end

      it 'is a discount' do
        charm = Discount::Percent.new(50).charm(0.99)
        expect(charm).to be_a(Discount::Base)
      end

      it 'exposes the discount' do
        percent = Discount::Percent.new(50)
        charm = percent.charm(0.99)
        expect(charm.discount).to eq(percent)
      end

      it 'exposes the ending' do
        charm = Discount::Percent.new(50).charm(0.99)
        expect(charm.ending).to eq(0.99)
      end

      it 'defaults to nearest rounding when applied' do
        charm = Discount::Fixed.new(0).charm(9)
        # 21 is closer to 19 than 29
        expect(charm.apply(21)).to eq(19)
        # 26 is closer to 29 than 19
        expect(charm.apply(26)).to eq(29)
      end

      it 'preserves to_formatted_s from wrapped discount' do
        charm = Discount::Percent.new(50).charm(0.99)
        expect(charm.to_formatted_s).to eq("50%")
      end
    end

    describe Discount::Charmed do
      describe '#up' do
        it 'rounds up to next price ending in .99' do
          discount = Discount::Percent.new(50).charm(0.99).up
          # 100 * 0.5 = 50 → round up to ending .99 → 50.99
          expect(discount.apply(100)).to eq(50.99)
        end

        it 'rounds up to next price ending in 9' do
          discount = Discount::Percent.new(50).charm(9).up
          # 99 * 0.5 = 49.5 → round up to ending 9 → 59
          expect(discount.apply(99)).to eq(59)
        end

        it 'stays at exact match' do
          discount = Discount::Fixed.new(0).charm(9).up
          expect(discount.apply(19)).to eq(19)
        end

        it 'is aliased as greedy' do
          discount = Discount::Percent.new(50).charm(0.99).greedy
          expect(discount.apply(100)).to eq(50.99)
        end
      end

      describe '#down' do
        it 'rounds down to previous price ending in .99' do
          discount = Discount::Percent.new(50).charm(0.99).down
          # 100 * 0.5 = 50 → round down to ending .99 → 49.99
          expect(discount.apply(100)).to eq(49.99)
        end

        it 'rounds down to previous price ending in 9' do
          discount = Discount::Percent.new(50).charm(9).down
          # 99 * 0.5 = 49.5 → round down to ending 9 → 49
          expect(discount.apply(99)).to eq(49)
        end

        it 'stays at exact match' do
          discount = Discount::Fixed.new(0).charm(9).down
          expect(discount.apply(19)).to eq(19)
        end

        it 'is aliased as generous' do
          discount = Discount::Percent.new(50).charm(0.99).generous
          expect(discount.apply(100)).to eq(49.99)
        end
      end

      it 'works with Fixed discounts' do
        discount = Discount::Fixed.new(10).charm(0.99).down
        # 100 - 10 = 90 → round down to ending .99 → 89.99
        expect(discount.apply(100)).to eq(89.99)
      end

      it 'preserves to_formatted_s from wrapped discount' do
        discount = Discount::Percent.new(50).charm(0.99).down
        expect(discount.to_formatted_s).to eq("50%")
      end

      it 'responds to to_discount' do
        discount = Discount::Percent.new(50).charm(0.99).down
        expect(discount.to_discount).to eq(discount)
      end

      describe 'prices ending in .99' do
        subject(:discount) { Discount::Fixed.new(0) }

        describe '.up' do
          subject(:charmed) { discount.charm(0.99).up }

          it { expect(charmed.apply(2.59)).to eq(2.99) }   # rounds up to .99
          it { expect(charmed.apply(2.99)).to eq(2.99) }   # exact match stays
          it { expect(charmed.apply(3.01)).to eq(3.99) }   # rounds up to next .99
          it { expect(charmed.apply(0.50)).to eq(0.99) }   # rounds up to 0.99
          it { expect(charmed.apply(0.0)).to eq(0.0) }     # zero stays zero
        end

        describe '.down' do
          subject(:charmed) { discount.charm(0.99).down }

          it { expect(charmed.apply(2.59)).to eq(1.99) }   # rounds down to .99
          it { expect(charmed.apply(2.99)).to eq(2.99) }   # exact match stays
          it { expect(charmed.apply(3.01)).to eq(2.99) }   # rounds down to .99
          it { expect(charmed.apply(0.50)).to eq(-0.01) }  # rounds down below zero
          it { expect(charmed.apply(0.0)).to eq(0.0) }     # zero stays zero
        end

        describe 'default (nearest)' do
          subject(:charm) { discount.charm(0.99) }

          it { expect(charm.apply(2.50)).to eq(2.99) }   # closer to 2.99 than 1.99
          it { expect(charm.apply(2.48)).to eq(1.99) }   # closer to 1.99 than 2.99
          it { expect(charm.apply(2.99)).to eq(2.99) }   # exact match stays
          it { expect(charm.apply(0.0)).to eq(0.0) }     # zero stays zero
        end
      end

      describe 'prices ending in 9' do
        subject(:discount) { Discount::Fixed.new(0) }

        describe '.up' do
          subject(:charmed) { discount.charm(9).up }

          it { expect(charmed.apply(18)).to eq(19) }    # rounds up to 19
          it { expect(charmed.apply(19)).to eq(19) }    # exact match stays
          it { expect(charmed.apply(20)).to eq(29) }    # rounds up to 29
          it { expect(charmed.apply(23.99)).to eq(29) } # rounds up to 29
          it { expect(charmed.apply(5)).to eq(9) }      # rounds up to 9
          it { expect(charmed.apply(0)).to eq(0) }      # zero stays zero
        end

        describe '.down' do
          subject(:charmed) { discount.charm(9).down }

          it { expect(charmed.apply(18)).to eq(9) }     # rounds down to 9
          it { expect(charmed.apply(19)).to eq(19) }    # exact match stays
          it { expect(charmed.apply(20)).to eq(19) }    # rounds down to 19
          it { expect(charmed.apply(23.99)).to eq(19) } # rounds down to 19
          it { expect(charmed.apply(5)).to eq(-1) }     # rounds down below zero
          it { expect(charmed.apply(0)).to eq(0) }      # zero stays zero
        end

        describe 'default (nearest)' do
          subject(:charm) { discount.charm(9) }

          it { expect(charm.apply(14)).to eq(9) }     # closer to 9 than 19
          it { expect(charm.apply(15)).to eq(19) }    # closer to 19 than 9
          it { expect(charm.apply(19)).to eq(19) }    # exact match stays
          it { expect(charm.apply(0)).to eq(0) }      # zero stays zero
        end
      end

      describe 'prices ending in 99' do
        subject(:discount) { Discount::Fixed.new(0) }

        describe '.up' do
          subject(:charmed) { discount.charm(99).up }

          it { expect(charmed.apply(150)).to eq(199) }  # rounds up to 199
          it { expect(charmed.apply(99)).to eq(99) }    # exact match stays
          it { expect(charmed.apply(100)).to eq(199) }  # rounds up to 199
          it { expect(charmed.apply(50)).to eq(99) }    # rounds up to 99
        end

        describe '.down' do
          subject(:charmed) { discount.charm(99).down }

          it { expect(charmed.apply(150)).to eq(99) }   # rounds down to 99
          it { expect(charmed.apply(99)).to eq(99) }    # exact match stays
          it { expect(charmed.apply(200)).to eq(199) }  # rounds down to 199
        end
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
