module Superfeature
  class Engine < ::Rails::Engine
    isolate_namespace Superfeature

    config.after_initialize do |app|
      # Add app/plans to the application's autoload paths
      plans_path = app.root.join("app/plans")
      Rails.autoloaders.main.push_dir(plans_path) if plans_path.exist?
    end
  end
end