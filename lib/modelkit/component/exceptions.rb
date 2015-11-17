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
    end
end
