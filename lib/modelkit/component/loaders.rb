module ModelKit
    module Component
        # Integration of ways to load oroGen models
        module Loaders
            extend Logger::Hierarchy
        end
    end
end

require 'modelkit/component/loaders/base'
require 'modelkit/component/loaders/files'
require 'modelkit/component/loaders/aggregate'
