# simplecov must be loaded FIRST. Only the files required after it gets loaded
# will be profiled !!!
if ENV['TEST_ENABLE_COVERAGE'] == '1'
    begin
        require 'simplecov'
        SimpleCov.start do
            add_filter "test"
        end
    rescue LoadError
        require 'modelkit/component'
        ModelKit::Component.warn "coverage is disabled because the 'simplecov' gem cannot be loaded"
    rescue Exception => e
        require 'modelkit/component'
        ModelKit::Component.warn "coverage is disabled: #{e.message}"
    end
end

begin
    require 'pry'
rescue LoadError
    require 'modelkit/component'
    ModelKit::Component.warn "debugging using pry is disabled as pry does not seem to be installed"
end

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'modelkit/component'
require 'minitest/autorun'
require 'flexmock/minitest'
require 'pp'

module ModelKit
    module Component
        module SelfTest
            def dummy_loader
                @dummy_loader ||= Loaders::Base.new
            end
            def dummy_project
                @dummy_project ||= Project.new(dummy_loader, name: 'dummy')
            end
            def dummy_node
                @dummy_node ||= Node.new_submodel(project: dummy_project, name: 'Task')
            end

            def create_dummy_type(typename)
                dummy_project.loader.registry.create_numeric(typename)
            end
            def create_dummy_interface_type(typename)
                type = create_dummy_type(typename)
                flexmock(dummy_loader).should_receive(:interface_type?).pass_thru.by_default
                flexmock(dummy_loader).should_receive(:interface_type?).with(type).and_return(true)
                type
            end
        end
    end
end

module Minitest
    class Test
        include ModelKit::Component::SelfTest
    end
end


