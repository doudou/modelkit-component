module ModelKit
    module Component
        # Base class for all exceptions representing the failure to find
        # something
        class NotFound < RuntimeError; end

        # Exception raised when looking for the typekit that defines a type, but
        # that typekit cannot be found
        class DefinitionTypekitNotFound < NotFound; end

        # Base clas for all exceptions representing a resolution of an object by
        # name, if multiple matches exist
        class AmbiguousName < RuntimeError; end

        # Exception raised when trying to resolve a deployed node by name, but
        # multiple matches exist
        class AmbiguousdeployedNodeName < AmbiguousName; end

        # Base class for all exceptions that represent an attempt to create an
        # invalid model
        class ModelError < RuntimeError; end
        
        # Exception raised when one tries to set incompatible combinations of
        # attributes on the models
        class Incompatibility < ModelError; end

        # Exception raised because of inconsistencies within the modelkit
        # library or extensions
        class InternalError < RuntimeError; end

        # Exception raised when attempting to register an object by name, but
        # another object of the same name already exists
        class AlreadyRegistered < RuntimeError; end

        # Exception raised when attempting to load a project that can't be found
        class ProjectNotFound < NotFound; end

        # Exception raised when attempting to load a project by name, but more than
        # one match exists
        class AmbiguousProjectName < AmbiguousName; end

        # Exception raised when attempting to load a project that can't be found
        class TypekitNotFound < NotFound; end

        # Exception raised when attempting to load a node model that can't be found
        class NodeModelNotFound < NotFound; end

        # Exception raised when attempting to load a node model by name, but more than
        # one match exists
        class AmbiguousNodeModelName < AmbiguousName; end

        # Exception raised when attempting to load a deployment model that can't be found
        class DeploymentModelNotFound < NotFound; end

        # Exception raised when attempting to load a deployment by name, but more than
        # one match exists
        class AmbiguousDeploymentName < AmbiguousName; end

        # Exception raised when attempting to load a deployed node model that can't be found
        class DeployedNodeModelNotFound < NotFound; end

        # Exception raised when attempting to load a deployed node model that can't be found
        class AmbiguousDeployedNodeName < AmbiguousName; end

        # Exception raised when an interface type was expected
        class NotInterfaceType < RuntimeError
            attr_reader :type, :definition_typekits

            def initialize(type, definition_typekits)
                @type = type
                @definition_typekits = definition_typekits
            end
        end

        # Exception raised in {Loaders::Aggregate#add} when attempting to add a
        # loader that is already registered
        class DuplicateLoader < ArgumentError; end
    end
end
