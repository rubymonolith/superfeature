require 'rails/generators'

module Superfeature
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_plans_directory
        empty_directory "app/plans"
      end

      def copy_application_plan
        template "application_plan.rb", "app/plans/application_plan.rb"
      end
    end
  end
end