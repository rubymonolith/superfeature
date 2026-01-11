require 'rails_helper'
require 'superfeature/core_ext'

RSpec.describe "Core extensions" do
  describe "Numeric#to_price" do
    it "converts integer to Price" do
      price = 10.to_price
      expect(price).to be_a(Superfeature::Price)
      expect(price.amount).to eq(10)
    end

    it "converts float to Price" do
      price = 49.99.to_price
      expect(price).to be_a(Superfeature::Price)
      expect(price.amount).to eq(BigDecimal("49.99"))
    end

    it "passes options through" do
      price = 100.to_price(range: nil)
      expect(price.range).to be_nil
    end

    it "works with BigDecimal" do
      price = BigDecimal("99.99").to_price
      expect(price.amount).to eq(BigDecimal("99.99"))
    end
  end

  describe "String#to_price" do
    it "converts numeric string to Price" do
      price = "49.99".to_price
      expect(price).to be_a(Superfeature::Price)
      expect(price.amount).to eq(BigDecimal("49.99"))
    end

    it "strips leading $" do
      price = "$100".to_price
      expect(price.amount).to eq(100)
    end

    it "strips leading $ with decimals" do
      price = "$49.99".to_price
      expect(price.amount).to eq(BigDecimal("49.99"))
    end

    it "strips whitespace after $" do
      price = "$ 25.00".to_price
      expect(price.amount).to eq(25)
    end

    it "passes options through" do
      price = "100".to_price(range: 0..50)
      expect(price.amount).to eq(50)
    end
  end

  describe "Numeric#percent_off" do
    it "creates a percentage discount" do
      discount = 20.percent_off
      expect(discount).to be_a(Superfeature::Discount::Percent)
      expect(discount.percent).to eq(20)
    end

    it "works with floats" do
      discount = 12.5.percent_off
      expect(discount.percent).to eq(BigDecimal("12.5"))
    end
  end

  describe "Numeric#discounted_by" do
    it "applies a percentage discount" do
      price = 100.discounted_by(20.percent_off)
      expect(price).to be_a(Superfeature::Price)
      expect(price.amount).to eq(80)
    end

    it "applies a fixed discount" do
      price = 100.discounted_by(15)
      expect(price.amount).to eq(85)
    end

    it "applies a string discount" do
      price = 100.discounted_by("25%")
      expect(price.amount).to eq(75)
    end

    it "works with floats" do
      price = 49.99.discounted_by(10.percent_off)
      expect(price.amount).to be_within(0.01).of(44.99)
    end
  end
end
