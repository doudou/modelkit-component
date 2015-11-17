require 'orogen'
require 'orogen/loaders'

#ModelKit.logger.level = Logger::DEBUG
loader = ModelKit::Loaders::Aggregate.new
ModelKit::Loaders::RTT.setup_loader(loader)
pkgconfig_loader = ModelKit::Loaders::PkgConfig.new(ENV['OROCOS_TARGET'], loader)
loader.add pkgconfig_loader
pkgconfig_loader.available_projects.each_key do |name|
    puts "loading #{name}"
    orogen = loader.project_model_from_name(name)
    puts "loaded #{name}"
end
