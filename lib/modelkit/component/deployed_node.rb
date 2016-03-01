module ModelKit
    module Component
        # Representation of a {Node} in a {Deployment}
        class DeployedNode
            # The node's deployment
            #
            # @return [Deployment]
            attr_reader :deployment
            # The node's deployed name
            #
            # @return [String]
            attr_reader :name
            # The node's model
            #
            # @return [Node]
            attr_reader :model

            def initialize(deployment, name, model)
                @deployment = deployment
                @name       = name.to_str
                @model      = model
            end
        end
    end
end

