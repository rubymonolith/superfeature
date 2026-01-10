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

      it 'exposes the discount' do
        percent = Discount::Percent.new(50)
        charm = percent.charm(0.99)
        expect(charm.discount).to eq(percent)
      end

      it 'exposes the multiple' do
        charm = Discount::Percent.new(50).charm(0.99)
        expect(charm.multiple).to eq(0.99)
      end
    end

    describe Discount::Charmed do
      describe '#up' do
        it 'rounds up to nearest multiple' do
          discount = Discount::Percent.new(50).charm(0.99).up
          # 100 * 0.5 = 50 → round up to nearest 0.99 → 50.49 (51 * 0.99)
          expect(discount.apply(100)).to eq(50.49)
        end

        it 'rounds up to nearest whole number multiple' do
          discount = Discount::Percent.new(50).charm(9).up
          # 99 * 0.5 = 49.5 → round up to nearest 9 → 54 (6 * 9)
          expect(discount.apply(99)).to eq(54)
        end

        it 'is aliased as greedy' do
          discount = Discount::Percent.new(50).charm(0.99).greedy
          expect(discount.apply(100)).to eq(50.49)
        end
      end

      describe '#down' do
        it 'rounds down to nearest multiple' do
          discount = Discount::Percent.new(50).charm(0.99).down
          # 100 * 0.5 = 50 → round down to nearest 0.99 → 49.5 (50 * 0.99)
          expect(discount.apply(100)).to eq(49.5)
        end

        it 'rounds down to nearest whole number multiple' do
          discount = Discount::Percent.new(50).charm(9).down
          # 99 * 0.5 = 49.5 → round down to nearest 9 → 45 (5 * 9)
          expect(discount.apply(99)).to eq(45)
        end

        it 'is aliased as generous' do
          discount = Discount::Percent.new(50).charm(0.99).generous
          expect(discount.apply(100)).to eq(49.5)
        end
      end

      describe '#round' do
        it 'rounds to nearest multiple (down)' do
          discount = Discount::Percent.new(50).charm(9).round
          # 90 * 0.5 = 45 → nearest 9 → 45 (5 * 9)
          expect(discount.apply(90)).to eq(45)
        end

        it 'rounds to nearest multiple (up)' do
          discount = Discount::Percent.new(50).charm(9).round
          # 100 * 0.5 = 50 → 50/9 = 5.55 → rounds to 6 → 54 (6 * 9)
          expect(discount.apply(100)).to eq(54)
        end
      end

      it 'works with Fixed discounts' do
        discount = Discount::Fixed.new(10).charm(0.99).down
        # 100 - 10 = 90 → round down to nearest 0.99 → 89.1 (90 * 0.99)
        expect(discount.apply(100)).to eq(89.1)
      end

      it 'preserves to_formatted_s from wrapped discount' do
        discount = Discount::Percent.new(50).charm(0.99).down
        expect(discount.to_formatted_s).to eq("50%")
      end

      it 'responds to to_discount' do
        discount = Discount::Percent.new(50).charm(0.99).down
        expect(discount.to_discount).to eq(discount)
      end

      describe 'edge cases with 0.99 charm' do
        subject(:discount) { Discount::Fixed.new(0) }

        describe '.down (floor - toward negative infinity)' do
          subject(:charmed) { discount.charm(0.99).down }

          it { expect(charmed.apply(1.99)).to eq(1.98) }   # 1.99/0.99=2.01 → floor=2 → 1.98
          it { expect(charmed.apply(0.99)).to eq(0.99) }   # exact multiple
          it { expect(charmed.apply(0.49)).to eq(0.0) }    # 0.49/0.99=0.49 → floor=0 → 0.0
          it { expect(charmed.apply(0.0)).to eq(0.0) }     # exact zero
          it { expect(charmed.apply(-0.50)).to eq(-0.99) } # -0.50/0.99=-0.50 → floor=-1 → -0.99
          it { expect(charmed.apply(-1.50)).to eq(-1.98) } # -1.50/0.99=-1.51 → floor=-2 → -1.98
        end

        describe '.up (ceil - toward positive infinity)' do
          subject(:charmed) { discount.charm(0.99).up }

          it { expect(charmed.apply(1.99)).to eq(2.97) }   # 1.99/0.99=2.01 → ceil=3 → 2.97
          it { expect(charmed.apply(0.99)).to eq(0.99) }   # exact multiple
          it { expect(charmed.apply(0.49)).to eq(0.99) }   # 0.49/0.99=0.49 → ceil=1 → 0.99
          it { expect(charmed.apply(0.01)).to eq(0.99) }   # 0.01/0.99=0.01 → ceil=1 → 0.99
          it { expect(charmed.apply(0.0)).to eq(0.0) }     # exact zero
          it { expect(charmed.apply(-0.50)).to eq(0.0) }   # -0.50/0.99=-0.50 → ceil=0 → 0.0
          it { expect(charmed.apply(-1.50)).to eq(-0.99) } # -1.50/0.99=-1.51 → ceil=-1 → -0.99
        end

        describe '.round (nearest)' do
          subject(:charmed) { discount.charm(0.99).round }

          it { expect(charmed.apply(1.99)).to eq(1.98) }   # 1.99/0.99=2.01 → round=2 → 1.98
          it { expect(charmed.apply(1.50)).to eq(1.98) }   # 1.50/0.99=1.51 → round=2 → 1.98
          it { expect(charmed.apply(1.48)).to eq(0.99) }   # 1.48/0.99=1.49 → round=1 → 0.99
          it { expect(charmed.apply(0.99)).to eq(0.99) }   # exact multiple
          it { expect(charmed.apply(0.50)).to eq(0.99) }   # 0.50/0.99=0.50 → round=1 → 0.99
          it { expect(charmed.apply(0.49)).to eq(0.0) }    # 0.49/0.99=0.49 → round=0 → 0.0
          it { expect(charmed.apply(0.0)).to eq(0.0) }     # exact zero
        end
      end

      describe 'edge cases with whole number charm (9)' do
        subject(:discount) { Discount::Fixed.new(0) }

        describe '.down (floor - toward negative infinity)' do
          subject(:charmed) { discount.charm(9).down }

          it { expect(charmed.apply(19)).to eq(18) }   # 19/9=2.11 → floor=2 → 18
          it { expect(charmed.apply(18)).to eq(18) }   # exact multiple
          it { expect(charmed.apply(17)).to eq(9) }    # 17/9=1.88 → floor=1 → 9
          it { expect(charmed.apply(9)).to eq(9) }     # exact multiple
          it { expect(charmed.apply(8)).to eq(0) }     # 8/9=0.88 → floor=0 → 0
          it { expect(charmed.apply(0)).to eq(0) }     # exact zero
          it { expect(charmed.apply(-1)).to eq(-9) }   # -1/9=-0.11 → floor=-1 → -9
          it { expect(charmed.apply(-9)).to eq(-9) }   # exact multiple
          it { expect(charmed.apply(-10)).to eq(-18) } # -10/9=-1.11 → floor=-2 → -18
        end

        describe '.up (ceil - toward positive infinity)' do
          subject(:charmed) { discount.charm(9).up }

          it { expect(charmed.apply(19)).to eq(27) }   # 19/9=2.11 → ceil=3 → 27
          it { expect(charmed.apply(18)).to eq(18) }   # exact multiple
          it { expect(charmed.apply(17)).to eq(18) }   # 17/9=1.88 → ceil=2 → 18
          it { expect(charmed.apply(9)).to eq(9) }     # exact multiple
          it { expect(charmed.apply(8)).to eq(9) }     # 8/9=0.88 → ceil=1 → 9
          it { expect(charmed.apply(1)).to eq(9) }     # 1/9=0.11 → ceil=1 → 9
          it { expect(charmed.apply(0)).to eq(0) }     # exact zero
          it { expect(charmed.apply(-1)).to eq(0) }    # -1/9=-0.11 → ceil=0 → 0
          it { expect(charmed.apply(-9)).to eq(-9) }   # exact multiple
          it { expect(charmed.apply(-10)).to eq(-9) }  # -10/9=-1.11 → ceil=-1 → -9
        end

        describe '.round (nearest)' do
          subject(:charmed) { discount.charm(9).round }

          it { expect(charmed.apply(18)).to eq(18) }   # exact multiple
          it { expect(charmed.apply(14)).to eq(18) }   # 14/9=1.55 → round=2 → 18
          it { expect(charmed.apply(13)).to eq(9) }    # 13/9=1.44 → round=1 → 9
          it { expect(charmed.apply(9)).to eq(9) }     # exact multiple
          it { expect(charmed.apply(5)).to eq(9) }     # 5/9=0.55 → round=1 → 9
          it { expect(charmed.apply(4)).to eq(0) }     # 4/9=0.44 → round=0 → 0
          it { expect(charmed.apply(0)).to eq(0) }     # exact zero
          it { expect(charmed.apply(-4)).to eq(0) }    # -4/9=-0.44 → round=0 → 0
          it { expect(charmed.apply(-5)).to eq(-9) }   # -5/9=-0.55 → round=-1 → -9
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
