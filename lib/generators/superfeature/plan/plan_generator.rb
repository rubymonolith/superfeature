require 'rails/generators'

module Superfeature
  module Generators
    class PlanGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_plan_file
        template "plan.rb.tt", "app/plans/#{file_name}.rb"
      end

      private

      def file_name
        # Remove "_plan" suffix if provided
        name = super
        name.delete_suffix("_plan")
      end

      def class_name
        # Remove "Plan" suffix if provided
        name = super
        name.delete_suffix("Plan")
      end
    end
  end
end