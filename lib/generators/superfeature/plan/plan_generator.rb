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
        # Remove "plan" suffix if it exists to avoid PlanPlan
        name = super
        name.end_with?("_plan") ? name : "#{name}_plan"
      end

      def class_name
        # Remove "Plan" suffix if it exists to avoid PlanPlan
        name = super
        name.end_with?("Plan") ? name : "#{name}Plan"
      end
    end
  end
end