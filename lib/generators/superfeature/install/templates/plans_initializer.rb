# frozen_string_literal: true

module Plans
  module Features
  end
end

Rails.autoloaders.main.push_dir(
  Rails.root.join("app/plans"), namespace: Plans
)
