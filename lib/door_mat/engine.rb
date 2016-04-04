module DoorMat
  class Engine < ::Rails::Engine
    isolate_namespace DoorMat

    initializer "door_mat.filter" do |app|
      app.config.filter_parameters += [:password]
    end

    # http://pivotallabs.com/leave-your-migrations-in-your-rails-engines/
    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    config.generators do |g|
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
    end
  end
end
