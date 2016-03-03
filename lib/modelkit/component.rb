require 'utilrb/logger'

module ModelKit
    module Component
        extend Logger::Root('ModelKit::Component', Logger::WARN)
    end
end

require 'utilrb/module/attr_predicate'
require 'utilrb/module/dsl_attribute'
require 'set'
require 'yaml'

require 'metaruby/dsls'

require 'modelkit/types'

require 'modelkit/component/version'

require 'modelkit/component/exceptions'

require 'modelkit/component/interface_object'
require 'modelkit/component/configuration_object'
require 'modelkit/component/attribute'
require 'modelkit/component/property'
require 'modelkit/component/operation'
require 'modelkit/component/port'
require 'modelkit/component/input_port'
require 'modelkit/component/output_port'

require 'modelkit/component/loaders'
require 'modelkit/component/dynamic_port'
require 'modelkit/component/dynamic_input_port'
require 'modelkit/component/dynamic_output_port'
require 'modelkit/component/project'
require 'modelkit/component/models/node'
require 'modelkit/component/node'
require 'modelkit/component/typekit'

require 'modelkit/component/deployed_node'
require 'modelkit/component/deployment'

module ModelKit
    module Component
        VoidType = Types::Type.new_submodel(typename: '/modelkit/component/void', null: true)
    end
end
