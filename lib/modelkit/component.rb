require 'utilrb/logger'

module ModelKit
    module Component
        extend Logger::Root('ModelKit::Component', Logger::INFO)
    end
end

require 'utilrb/module/attr_predicate'
require 'utilrb/module/dsl_attribute'
require 'set'

require 'metaruby/dsls'

require 'modelkit/types'

require 'modelkit/component/version'
require 'modelkit/component/doc'
require 'modelkit/component/enumerate_inherited'

require 'modelkit/component/exceptions'

require 'modelkit/component/configuration_object'
require 'modelkit/component/attribute'
require 'modelkit/component/property'

require 'modelkit/component/loaders'

require 'modelkit/component/opaque_definition'
require 'modelkit/component/operation'

require 'modelkit/component/port'
require 'modelkit/component/input_port'
require 'modelkit/component/output_port'
require 'modelkit/component/dynamic_ports'

require 'modelkit/component/project'
require 'modelkit/component/node'
require 'modelkit/component/typekit'
require 'modelkit/component/deployment'

module ModelKit
    module Component
        VoidType = Types::Type.new_submodel(typename: '/modelkit/component/void', null: true)
    end
end
