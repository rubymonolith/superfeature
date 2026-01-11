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
end
