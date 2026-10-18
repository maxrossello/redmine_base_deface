Redmine::Plugin.register :redmine_base_deface do
  name 'Redmine Base Deface plugin'
  author 'Jean-Baptiste BARTH'
  description 'This is a plugin for Redmine'
  version '6.1.5'
  url 'https://github.com/maxrossello/redmine_base_deface'
  author_url 'jeanbaptiste.barth@gmail.com'
end

require_relative "lib/redmine_base_deface/overrides_loader"

if Rails::VERSION::MAJOR >= 7
  RedmineBaseDeface::OverridesLoader.ignore_ruby_overrides
  RedmineBaseDeface::OverridesLoader.load_all

  Rails.application.config.after_initialize do
    require_relative "lib/applicator_patch"
  end
elsif Rails::VERSION::MAJOR == 6
  RedmineBaseDeface::OverridesLoader.ignore_ruby_overrides

  Rails.application.config.after_initialize do
    RedmineBaseDeface::OverridesLoader.load_all
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

