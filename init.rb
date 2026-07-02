Redmine::Plugin.register :redmine_base_deface do
  name 'Redmine Base Deface plugin'
  author 'Jean-Baptiste BARTH'
  description 'This is a plugin for Redmine'
  version '7.0.0'
  url 'https://github.com/maxrossello/redmine_base_deface'
  author_url 'jeanbaptiste.barth@gmail.com'
end

# Select the autoloader to use: zeitwerk or the classic one
# The `zeitwerk_enabled?` predicate returns `true` for Rails >= 7 
# For Rails 6.x, it returns `Rails.configuration.autoloader == :zeitwerk`
if Rails::VERSION::MAJOR >= 7
  Dir.glob("#{Rails.root}/plugins/*/app/overrides/**/*.rb").each do |path|
    Rails.autoloaders.main.ignore(path)
    load File.expand_path(path, __FILE__)
  end

  Dir.glob("#{Rails.root}/plugins/*/app/overrides/**/*.deface").each do |path|
    Deface::DSL::Loader::load File.expand_path(path, __FILE__)
  end

  Rails.application.config.after_initialize do
    require_relative "lib/applicator_patch"
  end
elsif Rails::VERSION::MAJOR == 6 && Rails.autoloaders.zeitwerk_enabled?
  Dir.glob("#{Rails.root}/plugins/*/app/overrides/**/*.rb").each do |path|
    Rails.autoloaders.main.ignore(path)
  end

  Rails.application.config.after_initialize do
    Dir.glob("#{Rails.root}/plugins/*/app/overrides/**/*.rb").each do |path|
      load File.expand_path(path, __FILE__)
    end
    Dir.glob("#{Rails.root}/plugins/*/app/overrides/**/*.deface").each do |path|
      Deface::DSL::Loader::load File.expand_path(path, __FILE__)
    end
    require_relative "lib/applicator_patch"
  end
else
  # Little hack for deface in redmine:
  # - redmine plugins are not railties nor engines, so deface overrides are not detected automatically
  # - deface doesn't support direct loading anymore ; it unloads everything at boot so that reload in dev works
  # - hack consists in adding "app/overrides" path of all plugins in Redmine's main #paths
  Rails.application.paths["app/overrides"] ||= []
  Dir.glob("#{Rails.root}/plugins/*/app/overrides").each do |dir|
    Rails.application.paths["app/overrides"] << dir unless Rails.application.paths["app/overrides"].include?(dir)
  end

  ActiveSupport::Reloader.to_prepare do
    require_dependency "applicator_patch"
  end
end

