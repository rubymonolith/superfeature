require 'rails/generators'

module Superfeature
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_plans_directory
        empty_directory "app/plans"
        empty_directory "app/plans/features"
        empty_directory "app/plans/tiers"
      end

      def copy_base_plan
        template "base.rb", "app/plans/base.rb"
      end

      def copy_features_base
        template "features/base.rb", "app/plans/features/base.rb"
      end

      def copy_tiers_base
        template "tiers/base.rb", "app/plans/tiers/base.rb"
      end

      def copy_plans
        template "free.rb", "app/plans/free.rb"
        template "paid.rb", "app/plans/paid.rb"
      end

      def create_initializer
        template "plans_initializer.rb", "config/initializers/plans.rb"
      end
    end
  end
end
