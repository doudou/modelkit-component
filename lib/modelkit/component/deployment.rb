module ModelKit
    module Component
        # A deployment, that is a collection of name-to-model representing a set
        # of deployed nodes
        class Deployment
            # A loader object that can be used to resolve task models
            attr_reader :loader
            # The deployment name
            attr_reader :name
            # The deployment's nodes
            #
            # @return [Hash<String,DeployedNode>]
            attr_reader :deployed_nodes

            def initialize(loader, name: nil)
                @loader = loader
                @name = name
                @deployed_nodes = Hash.new
            end

            # Deploy a node in this deployment
            def node(name, model)
                if model.respond_to?(:to_str)
                    model = loader.node_model_from_name(model)
                end

                name = name.to_str
                if deployed_nodes.has_key?(name)
                    raise ArgumentError, "#{self} already has a deployed task called #{name}, of model #{deployed_nodes[name]}"
                end

                deployed_nodes[name] = create_deployed_node(name, model)
            end

            # Resolves a deployed node by its name
            def deployed_node_from_name(name)
                deployed_nodes.fetch(name)
            end

            # @api private
            #
            # Factory method that creates a deployed-node object. This object
            # must respond to #name and #node_model
            def create_deployed_node(name, model)
                DeployedNode.new(self, name, model)
            end
        end
    end
end

