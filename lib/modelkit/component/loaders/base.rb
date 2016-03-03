module ModelKit
    module Component
        module Loaders
            # Definition of the base loader API
            class Base
                # Projects loaded so far
                #
                # @return [Hash<String,Project>]
                attr_reader :loaded_projects

                # Set of typekits loaded so far
                #
                # @return [Hash<String,Typekit>]
                attr_reader :loaded_typekits

                # Node models loaded so far
                #
                # @return [Hash<String,Node>]
                attr_reader :loaded_node_models

                # Deployment models loaded so far
                #
                # @return [Hash<String,Deployment>]
                attr_reader :loaded_deployment_models

                # All types loaded so far
                #
                # @return [ModelKit::Types::Registry]
                attr_reader :registry

                # The set of types that can be used on component interfaces
                # among the types loaded so far
                attr_reader :interface_types

                # A mapping from type names to the typekits that define them
                #
                # @return [Hash<String,Set<Typekit>>]
                attr_reader :typekits_by_type_name

                # The loader that should be used to resolve dependencies
                attr_reader :root_loader

                # Set of callbacks that are called whenever a new project gets
                # loaded
                #
                # @return [Array<#call>]
                attr_reader :project_load_callbacks

                # Set of callbacks that are called whenever a new typekit gets
                # loaded
                #
                # @return [Array<#call>]
                attr_reader :typekit_load_callbacks

                def initialize(root_loader = self)
                    @root_loader = root_loader
                    if root_loader != self
                        root_loader.added_child(self)
                    end
                    @typekit_load_callbacks = Array.new
                    @project_load_callbacks = Array.new
                    clear
                end

                def clear
                    @interface_types = Set.new
                    @loaded_projects = Hash.new
                    @loaded_typekits = Hash.new
                    @loaded_node_models = Hash.new
                    @loaded_deployment_models = Hash.new
                    @typekits_by_type_name = Hash.new
                    @registry = Types::Registry.new
                    registry.create_null '/modelkit/component/void'
                end

                # Hook called when this loader is used as a root loader on
                # another loader
                #
                # @param [Base] loader the loader that will use self as root
                def added_child(loader)
                end

                # Parse a textual representation of a project into a {Project}
                # object
                #
                # The default is to evaluate the text in the project's object
                # context
                #
                # @param [Project] project the project that is being set up by
                #   the text
                # @param [Project] project the project that is being set up by
                #   the text
                def parse_project_text(text, path: nil)
                    project = Project.new(root_loader)
                    if !path
                        project.instance_eval text
                    else
                        project.instance_eval text, path, 1
                    end
                    project
                end

                # Returns the project model corresponding to the given name
                #
                # @param [String] the project name
                # @raise [ProjectNotFound] if there is no project with that
                #   name.
                # @return [ModelKit::Component::Project]
                def project_model_from_name(name)
                    name = name.to_str
                    if project = loaded_projects[name]
                        return project
                    end

                    text, path = project_model_text_from_name(name)

                    Component.info "loading project #{name}"
                    project = parse_project_text(text, path: path)
                    project.typekit = typekit_model_from_name(name)
                    if project.name != name
                        raise InternalError, "inconsistency: got project #{project.name} while loading #{name}"
                    end
                    register_project_model(project)
                    project
                end
                
                # Registers this project's subobjects (node models and
                # deployment models)
                def register_project_model(project)
                    if loaded_projects.has_key?(project.name)
                        raise AlreadyRegistered, "there is already a project called #{project.name} registered on #{self}"
                    end

                    loaded_projects[project.name] = project
                    if root_loader != self
                        return root_loader.register_project_model(project)
                    end

                    project.each_node_model do |node_model|
                        register_node_model(node_model)
                    end
                    project.each_deployment_model do |deployment_model|
                        register_deployment_model(deployment_model)
                    end
                    project_load_callbacks.each do |callback|
                        callback.call(project)
                    end
                end

                # Registers a callback that should be called with newly registered
                # projects
                #
                # @param [Boolean] initial_events if true, the callbacks will be
                #   called instantly with the projects that have already been loaded
                def on_project_load(initial_events: true, &block)
                    project_load_callbacks << block
                    if initial_events
                        current_set = loaded_projects.values.dup
                        current_set.each do |p|
                            block.call(p)
                        end
                    end
                    block
                end

                # Removes the given callback from the listeners to {on_project_load}
                #
                # @param [Object] callback the value returned by {on_project_load}
                #   for the callback that should be removed
                def remove_project_load_callback(callback)
                    project_load_callbacks.delete(callback)
                end

                # Whether a project with this name is already loaded
                #
                # @param [String] name the name of the project to test for
                def has_loaded_project?(name)
                    loaded_projects.has_key?(name)
                end

                def parse_typekit_text(text, path: path)
                    metainfo = YAML.load(text)
                    if xml_section_index = (text =~ /<typelib>/)
                        xml_section = text[xml_section_index..-1]
                    else
                        raise ArgumentError, "given text does not contain a modelkit-types XML section"
                    end


                    registry = Types::Registry.from_xml(REXML::Document.new(xml_section))

                    name = metainfo.fetch('name')
                    typelist = metainfo.fetch('typelist').
                        map { |typename| registry.get(typename) }
                    interface_typelist = metainfo.fetch('interface_typelist').
                        map { |typename| registry.get(typename) }

                    Typekit.new(root_loader, name: name,
                                registry: registry,
                                typelist: typelist,
                                interface_typelist: interface_typelist)
                end

                # Loads a typekit from its name
                #
                # @param [String] name the typekit name
                # @return [Component::Typekit] the typekit
                # @raise [TypekitNotFound] if the typekit cannot be found
                def typekit_model_from_name(name)
                    if typekit = loaded_typekits[name]
                        return typekit
                    end

                    text, path = typekit_model_text_from_name(name)
                    typekit = parse_typekit_text(text, path: path)
                    if typekit.name != name
                        raise InternalError, "inconsistency: got typekit #{typekit.name} while loading #{name}"
                    end

                    register_typekit_model(typekit)
                    typekit
                end

                # Registers information from this typekit
                #
                # Callbacks registered by {#on_typekit_load} gets called with the
                # new typekit as argument
                def register_typekit_model(typekit)
                    if loaded_typekits.has_key?(typekit.name)
                        raise AlreadyRegistered, "there is already a typekit called #{typekit.name} registered on #{self}"
                    end

                    loaded_typekits[typekit.name] = typekit
                    if root_loader != self
                        return root_loader.register_typekit_model(typekit)
                    end

                    registry.merge typekit.registry
                    interface_types.merge(typekit.interface_typelist.map { |t| registry.get(t.name) })
                    typekit.registry.each(with_aliases: true) do |typename, _|
                        typekits_by_type_name[typename] ||= Set.new
                        typekits_by_type_name[typename] << typekit
                    end
                    typekit_load_callbacks.each do |callback|
                        callback.call(typekit)
                    end
                end

                # Registers a callback that should be called with newly registered
                # typekits
                #
                # @param [Boolean] initial_events if true, the callbacks will be
                #   called instantly with the typekits that have already been loaded
                def on_typekit_load(initial_events: true, &block)
                    typekit_load_callbacks << block
                    if initial_events
                        current_set = loaded_typekits.values.dup
                        current_set.each do |tk|
                            block.call(tk)
                        end
                    end
                    block
                end

                # Removes the given callback from the listeners to
                # {on_typekit_load}
                #
                # @param [Object] callback the value returned by
                #   {on_typekit_load} for the callback that should be removed
                def remove_typekit_load_callback(callback)
                    typekit_load_callbacks.delete(callback)
                end

                # Whether a typekit with this name is already loaded
                #
                # @param [String] name the name of the typekit to test for
                def has_loaded_typekit?(name)
                    loaded_typekits.has_key?(name)
                end

                # Returns the node library model corresponding to the given name
                # @param (see project_model_from_name)
                # @raise [ProjectNotFound] if there is no node library with that
                #   name. This does including having a project with that name if the
                #   project defines no nodes.
                # @return (see project_model_from_name)
                def node_library_model_from_name(name)
                    project = project_model_from_name(name)
                    if project.node_models.empty?
                        raise ProjectNotFound, "there is a project called #{name}, but it defines no node models"
                    end
                    project
                end

                # Returns the node model object corresponding to a model name
                #
                # @param [String] name the node model name
                # @return [Component::Node]
                # @raise [NodeModelNotFound] if there are no such model
                # @raise (see project_model_from_name)
                def node_model_from_name(name)
                    if model = loaded_node_models[name]
                        return model
                    end

                    project_name = find_project_name_from_node_model_name(name)
                    if !project_name
                        raise NodeModelNotFound, "no node model #{name} is registered"
                    end

                    project = project_model_from_name(project_name)
                    if !project.has_node_model?(name)
                        raise InternalError, "while looking up model of #{name}: found project #{project_name}, but this node library does not actually have a node model called #{name}"
                    end
                    loaded_node_models.fetch(name)
                end

                # Returns the deployment model for the given deployment name
                #
                # @param [String] name the deployment name
                # @return [ModelKit::Component::Deployment] the deployment model
                # @raise [DeploymentModelNotFound] if no deployment with that name exists
                def deployment_model_from_name(name)
                    if model = loaded_deployment_models[name]
                        return model
                    end

                    project_name = find_project_name_from_deployment_model_name(name)
                    if !project_name
                        raise DeploymentModelNotFound, "there is no deployment called #{name} on #{self}"
                    end

                    project = project_model_from_name(project_name)
                    if !project.has_deployment_model?(name)
                        raise InternalError, "while looking up model of #{name}: found project #{project_name}, but this project does not actually have a deployment model called #{name}"
                    end
                    loaded_deployment_models.fetch(name)
                end

                # Returns the deployed node model for the given name
                #
                # @param [String] name the deployed node name
                # @param [String] deployment_name () the name of the deployment in which the
                #   node is defined. It must be given only when more than one deployment
                #   defines a node with the requested name
                # @return [ModelKit::Component::NodeDeployment] the deployed node model
                # @raise [DeployedNodeModelNotFound] if no deployed nodes with that name exists
                # @raise [DeployedNodeModelNotFound] if deployment_name was given, but the requested
                #   node is not defined in this deployment
                # @raise [ModelKit::AmbiguousName] if more than one node exists with that
                #   name. In that case, you will have to provide the deployment name
                #   explicitly using the second argument
                def deployed_node_model_from_name(name, deployment_name: nil)
                    if deployment_name
                        deployment = deployment_model_from_name(deployment_name)
                    else
                        deployment_names = find_deployment_model_names_from_deployed_node_name(name)
                        if deployment_names.empty?
                            raise DeployedNodeModelNotFound, "cannot find a deployed node called #{name}"
                        elsif deployment_names.size > 1
                            raise AmbiguousDeployedNodeName, "more than one deployment defines a deployed node called #{name}: #{deployment_names.sort.join(", ")}"
                        end
                        deployment = deployment_model_from_name(deployment_names.first)
                    end

                    if !deployment.has_deployed_node?(name)
                        exception_class =
                            if deployment_name then ArgumentError
                            else InternalError
                            end

                        raise exception_class, "found #{deployment} as the only deployment providing a deployed node called #{name}, but the deployment model does not actually have it"
                    end
                    deployment.deployed_node_from_name(name)
                end

                # Resolves a type object
                #
                # @param [#name,String] type the type to be resolved
                # @return [Model<Types::Type>] the corresponding type in
                #   {#registry}
                # @raise Types::NotFound if the type cannot be found
                def resolve_type(type)
                    typename =
                        if type.respond_to?(:name)
                            type.name
                        else type
                        end
                    registry.get(typename)
                end

                # Returns the typekit object that defines this type
                #
                # @option options [Boolean] :definition_typekits (true) if true,
                #   only the typekits that actually have the type in their typelist
                #   are returned. Otherwise, every typekit that have it in their
                #   registry are returned.
                #
                # @return [Set<Component::Typekit>] the list of typekits
                # @raise [DefinitionTypekitNotFound] if no typekits define this type
                def imported_typekits_for(typename, definition_typekits: true)
                    if typename.respond_to?(:name)
                        typename = typename.name
                    end
                    if typekits = typekits_by_type_name[typename]
                        if definition_typekits
                            definition_typekits = typekits.find_all { |tk| tk.include?(typename) }
                            if definition_typekits.empty?
                                raise DefinitionTypekitNotFound, "typekits #{typekits.map(&:name).sort.join(", ")} have #{typename} in their registries, but it seems that all of them got it from another typekit and definition_typekits is true"
                            end
                            return definition_typekits.to_set
                        else
                            return typekits
                        end
                    end
                    raise DefinitionTypekitNotFound, "#{typename} is not defined by any typekits loaded so far"
                end

                # Returns the type object from its name, validating that we can
                # use it in a node's interface
                #
                # @param [String] typename
                # @raise [InvalidInterfaceType] if the type is known but cannot
                #   be used on the interface
                # @raise (see resolve_type)
                # @raise [NotExportedType] if the type is known but cannot be
                #   used on the interface
                def resolve_interface_type(typename)
                    type = resolve_type(typename)
                    if !interface_type?(type)
                        typekits = imported_typekits_for(type.name)
                        raise NotInterfaceType.new(type, typekits), "#{type.name}, defined in the #{typekits.map(&:name).join(", ")} typekits, is never exported"
                    end
                    type
                end

                # Tests whether the given type can be used on an interface
                #
                # @param [#name,String] typename the type
                # @return [Boolean]
                def interface_type?(typename)
                    interface_types.include?(resolve_type(typename))
                end

                # Registers a new type model
                #
                # @param [Types::Type] the type model
                # @return [void]
                def register_type_model(type)
                    registry.merge type.registry.minimal(type.name)
                end
                
                # Registers a new node model
                #
                # @param [Component::Node] model
                # @return [void]
                def register_node_model(model)
                    loaded_node_models[model.name] = model
                    if root_loader != self
                        root_loader.register_node_model(model)
                    end
                end

                # Registers a new deployment model
                #
                # @param [Component::Deployment] model
                # @return [void]
                def register_deployment_model(model)
                    loaded_deployment_models[model.name] = model
                    if root_loader != self
                        root_loader.register_deployment_model(model)
                    end
                end

                # Returns the textual representation of a project model
                #
                # @param [String] the project name
                # @raise [ProjectNotFound] if there is no project with that
                #   name.
                # @return [(String,String)] the model as text, as well as a path to
                #   the model file (or nil if there is no such file)
                def project_model_text_from_name(name)
                    raise ProjectNotFound, "subclass #{self} need to reimplement #project_model_text_from_name or #project_model_from_name"
                end

                # Returns the textual representation of a typekit
                #
                # @param [String] the typekit name
                # @raise [TypekitNotFound] if there is no typekit with that name
                # @return [(String,String)] the typekit registry as XML and the
                #   typekit's typelist
                def typekit_model_text_from_name(name)
                    raise TypekitNotFound, "subclass #{self} need to reimplement #typekit_model_text_from_name or #typekit_model_from_name"
                end

                # Tests if a project with that name exists
                #
                # @param [String] name the project name
                # @return [Boolean]
                def project_available?(name)
                    raise NotImplementedError
                end

                # Tests if a typekit with that name exists
                #
                # @param [String] name the typekit name
                # @return [Boolean]
                def typekit_available?(name)
                    raise NotImplementedError
                end

                # Returns the project that defines a given node model
                #
                # @param [String] deployment_name the deployment we are looking for
                # @return [String,nil]
                def find_project_name_from_node_model_name(name)
                    loaded_projects.each do |project_name, project|
                        if project.has_node_model?(name)
                            return project_name
                        end
                    end
                    nil
                end

                # Returns the project that defines the given deployment
                #
                # @param [String] deployment_name the deployment we are looking for
                # @return [String,nil]
                def find_project_name_from_deployment_model_name(name)
                end

                # Returns the set of deployments that contain a certain node
                #
                # @param [String] name
                # @return [Set<String>]
                def find_deployment_model_names_from_deployed_node_name(name)
                    result = Set.new
                    loaded_deployment_models.each do |deployment_name, deployment_m|
                        if deployment_m.has_deployed_node?(name)
                            result << deployment_name
                        end
                    end
                    result
                end

                # Enumerates the names of all available projects
                #
                # @yieldparam [String] project_name
                def each_available_project_name
                    return enum_for(__method__) if !block_given?
                    nil
                end

                def inspect
                    to_s
                end
            end
        end
    end
end
