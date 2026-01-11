module Superfeature
  class Engine < ::Rails::Engine
    isolate_namespace Superfeature

    initializer "superfeature.core_ext" do
      require "superfeature/core_ext"
    end
  end
end