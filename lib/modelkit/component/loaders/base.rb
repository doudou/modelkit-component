module ModelKit
    module Component
        module Loaders
            # Definition of the base loader API
            class Base
                # Set of projects loaded so far
                #
                # @return [Hash<String,Component::Project>]
                attr_reader :loaded_projects

                # Set of node models that are known to us
                #
                # @return [Hash<String,Node>]
                attr_reader :loaded_node_models

                # Set of deployment models that are known to us
                attr_reader :loaded_deployment_models

                # The registry that includes types from all loaded typekits
                #
                # @return [ModelKit::Types::Registry]
                attr_reader :registry

                # A mapping from type names to the typekits that define them
                #
                # @return [Hash<ModelKit::Types::Type,Set<String>>]
                attr_reader :typekits_by_type_name

                # Set of typekits loaded so far
                #
                # @return [Hash<String,Typekit>]
                attr_reader :loaded_typekits

                # The loader that should be used to resolve dependencies
                attr_reader :root_loader

                # Sets the behaviour of the type resolution on unknown types
                #
                # @return [Boolean]
                attr_predicate :define_dummy_types?, true

                # Set of callbacks that are called whenever a new typekit gets
                # loaded
                #
                # @return [Array<#call>]
                attr_reader :typekit_load_callbacks

                # Set of callbacks that are called whenever a new typekit gets
                # loaded
                #
                # @return [Array<#call>]
                attr_reader :project_load_callbacks

                # @api private
                #
                # Cached parsed XML from the typekits
                #
                # This is to avoid repeatedly parsing the same XML. It is really
                # useful only on test suites which tend to clear and reload loaders
                # at each setup/teardown
                attr_reader :typekit_xml_cache

                TypekitXMLCacheEntry = Struct.new :text, :rexml

                def initialize(root_loader = self)
                    @root_loader = root_loader || self
                    if root_loader != self
                        root_loader.added_child(self)
                    end
                    @typekit_load_callbacks = Array.new
                    @project_load_callbacks = Array.new
                    @typekit_xml_cache = Hash.new
                    clear
                end

                def clear
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
                def parse_project_text(project, path, text, verbose: false)
                    if !path
                        project.instance_eval text
                    else
                        project.instance_eval text, path, 1
                    end
                    self
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
                    project = Component::Project.new(root_loader)
                    project.typekit = typekit_model_from_name(name)
                    parse_project_text(project, path, text)
                    if project.name != name
                        raise InternalError, "inconsistency: got project #{project.name} while loading #{name}"
                    end
                    register_project_model(project)
                    project
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

                    nodelib_name = find_node_library_from_node_model_name(name)
                    if !nodelib_name
                        raise NodeModelNotFound, "no node model #{name} is registered"
                    end

                    nodelib = project_model_from_name(nodelib_name)
                    result = nodelib.node_models[name]
                    if !result
                        raise InternalError, "while looking up model of #{name}: found project #{nodelib_name}, but this project does not actually have a node model called #{name}"
                    end

                    result
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

                    project_name = find_project_from_deployment_name(name)
                    if !project_name
                        raise DeploymentModelNotFound, "there is no deployment called #{name} on #{self}"
                    end

                    project = project_model_from_name(project_name)
                    deployment = project.deployers[name]
                    if !deployment
                        raise InternalError, "cannot find the deployment called #{name} in #{project.name}. Candidates were #{project.deployers.map(&:name).sort.join(", ")}"
                    end
                    deployment
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
                def deployed_node_model_from_name(name, deployment_name = nil)
                    if deployment_name
                        deployment = deployment_model_from_name(deployment_name)
                    else
                        deployment_names = find_deployments_from_deployed_node_name(name)
                        if deployment_names.empty?
                            raise DeployedNodeModelNotFound, "cannot find a deployed node called #{name}"
                        elsif deployment_names.size > 1
                            raise AmbiguousdeployedNodeName, "more than one deployment defines a deployed node called #{name}: #{deployment_names.map(&:name).sort.join(", ")}"
                        end
                        deployment = deployment_model_from_name(deployment_names.first)
                    end

                    if !(node = deployment.find_node_by_name(name))
                        if deployment_name
                            raise DeployedNodeModelNotFound, "deployment #{deployment_name} does not have a node called #{name}"
                        else
                            raise InternalError, "deployment #{deployment_name} was supposed to have a node called #{name} but does not"
                        end
                    end
                    node
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

                    registry_xml, typelist_txt = typekit_model_text_from_name(name)
                    if (cached = typekit_xml_cache[name]) && (registry_xml == cached.text)
                        parsed_xml = cached.rexml
                    else
                        parsed_xml = REXML::Document.new(registry_xml)
                        typekit_xml_cache[name] = TypekitXMLCacheEntry.new(registry_xml, parsed_xml)
                    end
                    typekit = Component::Typekit.from_raw_data(root_loader, name, registry_xml, typelist_txt,
                                                          parsed_xml: parsed_xml)
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
                    typekit.registry.each(with_aliases: true) do |typename, _|
                        typekits_by_type_name[typename] ||= Set.new
                        typekits_by_type_name[typename] << typekit
                    end
                    typekit_load_callbacks.each do |callback|
                        callback.call(typekit)
                    end
                end

                def register_type_model(type)
                    registry.merge type.registry.minimal(type.name)
                end
                
                # Registers a callback that should be called with newly registered
                # typekits
                #
                # @param [Boolean] initial_events if true, the callbacks will be
                #   called instantly with the typekits that have already been loaded
                def on_typekit_load(initial_events = true, &block)
                    typekit_load_callbacks << block
                    if initial_events
                        current_set = loaded_typekits.values.dup
                        current_set.each do |tk|
                            block.call(tk)
                        end
                    end
                end

                # Resolves a type object
                #
                # @param [#name,String] type the type to be resolved
                # @return [Model<Types::Type>] the corresponding type in
                #   {#registry}
                # @raise Types::NotFound if the type cannot be found
                def resolve_type(type, define_dummy_types: false)
                    typename =
                        if type.respond_to?(:name)
                            type.name
                        else type
                        end
                    registry.get(typename)
                rescue Types::NotFound => e
                    if define_dummy_types? || define_dummy_types
                        return registry.create_null(typename)
                    else raise e, "#{e.message} using #{self}", e.backtrace
                    end
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
                    options = Kernel.validate_options options,
                        :definition_typekits => true
                    if typename.respond_to?(:name)
                        typename = typename.name
                    end
                    if typekits = typekits_by_type_name[typename]
                        if options[:definition_typekits]
                            definition_typekits = typekits.find_all { |tk| tk.include?(typename) }
                            if definition_typekits.empty?
                                raise DefinitionTypekitNotFound, "typekits #{typekits.map(&:name).sort.join(", ")} have #{typename} in their registries, but it seems that they got it from another typekit and I cannot find it. definition_typekits is true, I raise"
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
                        raise NotExportedType.new(type, typekits), "#{type.name}, defined in the #{typekits.map(&:name).join(", ")} typekits, is never exported"
                    end
                    type
                end

                # Tests whether the given type can be used on an interface
                #
                # @param [#name,String] typename the type
                # @return [Boolean]
                def interface_type?(typename)
                    typename = typename.name if typename.respond_to?(:name)
                    interface_typelist.include?(typename)
                end

                # Tests whether the given type can be used on an interface
                #
                # @param (see Component::Typekit#intermediate_type?)
                # @return (see Component::Typekit#intermediate_type?)
                def intermediate_type?(type)
                    imported_typekits_for(type, definition_typekits: false).
                        any? { |tk| tk.intermediate_type?(type) }
                end

                # Returns the opaque type that is paired with the given type
                #
                # @param (see Component::Typekit#opaque_type_for)
                # @raise (see Component::Typekit#opaque_type_for)
                # @return (see Component::Typekit#opaque_type_for)
                def opaque_type_for(type)
                    type = imported_typekits_for(type, definition_typekits: false).
                        first.opaque_type_for(type)
                    registry.get(type.name)
                end

                # Returns the intermediate type that is paired with the given type
                #
                # @param (see Component::Typekit#opaque_type_for)
                # @raise (see Component::Typekit#opaque_type_for)
                # @return (see Component::Typekit#opaque_type_for)
                def intermediate_type_for(type)
                    type = imported_typekits_for(type, definition_typekits: false).
                        first.intermediate_type_for(type)
                    registry.get(type.name)
                end

                # Returns whether this type is a m-type (intermediate type generated
                # by oroGen)
                #
                # @param (see Component::Typekit#m_type?)
                # @raise (see Component::Typekit#m_type?)
                # @return (see Component::Typekit#m_type?)
                def m_type?(type)
                    imported_typekits_for(type, definition_typekits: false).
                        first.m_type?(type)
                end

                # Registers this project's subobjects
                def register_project_model(project)
                    if loaded_projects.has_key?(project.name)
                        raise AlreadyRegistered, "there is already a project called #{project.name} registered on #{self}"
                    end

                    loaded_projects[project.name] = project
                    if root_loader != self
                        return root_loader.register_project_model(project)
                    end

                    project.node_models.each do |_, node_model|
                        register_node_model(node_model)
                    end
                    project_load_callbacks.each do |callback|
                        callback.call(project)
                    end
                end

                def has_loaded_project?(name)
                    loaded_projects.has_key?(name)
                end

                # Registers a new node model
                #
                # @param [Component::Node] model
                # @return [void]
                def register_node_model(model)
                    loaded_node_models[model.name] = model
                end

                # Registers a new deployment model
                #
                # @param [Component::Deployment] model
                # @return [void]
                def register_deployment_model(model)
                    loaded_deployment_models[model.name] = model
                end

                # Returns the textual representation of a project model
                #
                # @param [String] the project name
                # @raise [ProjectNotFound] if there is no project with that
                #   name.
                # @return [(String,String)] the model as text, as well as a path to
                #   the model file (or nil if there is no such file)
                def project_model_text_from_name(name)
                    raise NotImplementedError
                end

                # Returns the textual representation of a typekit
                #
                # @param [String] the typekit name
                # @raise [TypekitNotFound] if there is no typekit with that name
                # @return [(String,String)] the typekit registry as XML and the
                #   typekit's typelist
                def typekit_model_text_from_name(name)
                    raise NotImplementedError
                end

                # Tests if a project with that name exists
                #
                # @param [String] name the project name
                # @return [Boolean]
                def has_project?(name)
                    raise NotImplementedError
                end

                # Tests if a typekit with that name exists
                #
                # @param [String] name the typekit name
                # @return [Boolean]
                def has_typekit?(name)
                    raise NotImplementedError
                end

                # Returns the node library name in which a node model is defined
                #
                # @param [String] model_name the name of the node model to look for
                # @return [String,nil]
                def find_node_library_from_node_model_name(name)
                    loaded_projects.each_value do |project|
                        if project.has_node_model?(name)
                            return project
                        end
                    end

                    raise ArgumentError, "#{self.class} cannot find the node library which defines #{name}. You need to load it explicitely with #node_library_model_from_name before calling #node_model_from_name"
                end

                # Returns the project that defines the given deployment
                #
                # @param [String] deployment_name the deployment we are looking for
                # @return [String,nil]
                def find_project_from_deployment_name(name)
                end

                # Returns the set of deployments that contain a certain node
                #
                # @param [String] name
                # @return [Set<String>]
                def find_deployments_from_deployed_node_name(name)
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
