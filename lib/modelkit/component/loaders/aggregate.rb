module ModelKit::Component
    module Loaders
        # A launcher that aggregates other launchers
        class Aggregate < Base
            # @return [Array]
            attr_reader :loaders

            def initialize(root_loader = self)
                @loaders = Array.new
                super(root_loader)
            end

            def added_child(loader)
                add(loader)
            end

            def clear
                super
                loaders.each do |l|
                    l.clear
                end
            end

            def add(loader)
                if loaders.include?(loader)
                    raise DuplicateLoader, "#{loader} is already a child of #{self}"
                end
                @loaders << loader
            end

            def remove(loader)
                @loaders.delete loader
            end

            # @api private
            #
            # Helper method to handle all the other loading methods
            def query_registered_loaders(kind, name, query_method, not_found)
                Loaders.debug "Aggregate: resolving #{kind} #{name} on #{loaders.map(&:to_s).join(",")}"
                loaders.each do |l|
                    begin
                        # We assume that the sub-loaders are created with self
                        # as root loader. They will therefore register
                        # newly loaded projects on self
                        return l.send(query_method, name)
                    rescue not_found => e
                        Loaders.debug "  not available on #{l}: #{e}"
                    end
                end
                raise not_found, "there is no #{kind} named #{name} on #{self}"
            end

            def project_model_from_name(name)
                if project = loaded_projects[name]
                    return project
                end
                query_registered_loaders('project', name, __method__, ProjectNotFound)
            end

            def typekit_model_from_name(name)
                if typekit = loaded_typekits[name]
                    return typekit
                end
                query_registered_loaders('typekit', name, __method__, TypekitNotFound)
            end

            def node_model_from_name(name)
                if model = loaded_node_models[name]
                    return model
                end
                query_registered_loaders('node model', name, __method__, NodeModelNotFound)
            end

            def deployment_model_from_name(name)
                if model = loaded_deployment_models[name]
                    return model
                end
                query_registered_loaders('deployment model', name, __method__, DeploymentModelNotFound)
            end

            def deployed_node_model_from_name(name)
                query_registered_loaders('deployed node', name, __method__, DeployedNodeModelNotFound)
            end
        end
    end
end

