module Plans
  module Tiers
    class Base < Superfeature::Tiers
      tier Plans::Free
      tier Plans::Paid
    end
  end
end
