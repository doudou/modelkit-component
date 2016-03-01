module ModelKit
    module Component
        # Representation of an oroGen project
        class Project
            # The loader that should be used to resolve dependencies
            attr_reader :loader

            # The project's typekit
            attr_accessor :typekit

            # The node models defined by this project
            #
            # @return [Hash<String,Node>]
            attr_reader :node_models

            # The deployments this project defines
            #
            # @return [Hash<String,Deployment>]
            attr_reader :deployment_models

            # The Node submodel that should be used by {#node} as supermodel by
            # default
            attr_accessor :default_node_supermodel

            # Create an empty project built on top of an empty loader
            def self.blank
                Project.new(Loaders::Base.new)
            end

            def initialize(loader, name: nil)
                @name = name
                @loader = loader
                @default_node_supermodel = Node
                @node_models = Hash.new
                @deployment_models = Hash.new
            end

            # Gets or sets the project's name
            #
            # @overload name
            #   @return [String] this project's name
            # @overload name(new_name)
            #   @param [String] the name that should be set
            #   @return [self]
            dsl_attribute :name do |new|
                if !new.respond_to?(:to_str)
                    raise ArgumentError, 'name should be a string'
                end
                new
            end

            # Gets or sets the project's version
            #
            # @overload version
            #   The version number of this project. Defaults to "0.0"
            #   @return [String]
            # @overload version(new_version)
            #   @param [String] new_version the new version
            #   @return [String]
            dsl_attribute :version do |name|
                name = name.to_s
                if name !~ /^\d/
                    raise ArgumentError, "version strings must start with a number (had: #{name})"
                end
                name
            end

            # Make the nodes from another node library / project available to
            # this project, to use as a node superclass or in a deployment
            #
            # @param [String,Project] nodelib the node library, or its name. In
            #   the latter case, the node library will be loaded with {#loader}
            #
            # @see use_types_from
            def use_nodes_from(nodelib)
                if nodelib.respond_to?(:to_str)
                    loader.node_library_model_from_name(nodelib)
                else loader.register_project_model(nodelib)
                end
            end

            # Creates a new node model and register it on this project
            #
            # @param [String] name the new model's name
            # @param [Model<Node>] supermodel the new model's supermodel,
            #   {#default_node_supermodel} by default
            # @return [Model<Node>] the new model
            def node(name, supermodel: default_node_supermodel, &block)
                if has_node_model?(name)
                    raise ArgumentError, "there is already a node model named #{name} registered"
                end

                node_model = supermodel.new_submodel(name: name)
                node_model.instance_eval(&block) if block_given?
                node_models[node_model.name] = node_model
                loader.register_node_model(node_model)
                node_model
            end

            # Create a new deployment model and register it on self
            #
            # @param [String] name the deployment name
            def deployment(name, supermodel: Deployment, &block)
                if existing = deployment_models[name]
                    raise ArgumentError, "there is already a deployment called #{name} in #{self}"
                end

                deployment_model = supermodel.new(loader, name: name)
                deployment_model.instance_eval(&block) if block_given?
                deployment_models[deployment_model.name] = deployment_model
                loader.register_deployment_model(deployment_model)
                deployment_model
            end

            # Make the types available in the given typekit available to this
            # project
            #
            # @see use_nodes_from
            def use_types_from(typekit)
                if typekit.respond_to?(:to_str)
                    loader.typekit_model_from_name(typekit)
                else loader.register_typekit_model(typekit)
                end
            end

            # Checks if this project already has a node model with the given
            # name
            def has_node_model?(name)
                node_models.has_key?(name.to_str)
            end

            # (see Loaders::Base#node_model_from_name)
            def node_model_from_name(name)
                node_models[name] || loader.node_model_from_name(name)
            end

            def has_deployment_model?(name)
                deployment_models.has_key?(name.to_str)
            end

            def deployment_model_from_name(name)
                deployment_models.fetch(name)
            end

            # Displays the content of this oroGen project in a nice form
            def pretty_print(pp) # :nodoc:
                if !node_models.empty?
                    pp.text "  Node Models"
                    pp.nest(4) do
                        pp.breakable
                        pp.seplist(node_models.values.sort_by(&:name)) do |t|
                            t.pretty_print(pp)
                        end
                    end
                end
            end

            def to_s
                "#<#{self.class}: name=#{name} loader=#{loader}>"
            end
        end
    end
end
