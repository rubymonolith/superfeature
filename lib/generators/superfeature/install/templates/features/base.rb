module Plans
  module Features
    class Base < Superfeature::Feature
      attr_reader :name, :group

      def initialize(name = nil, group: nil, **)
        super(**)
        @name = name
        @group = group
      end
    end
  end
end
