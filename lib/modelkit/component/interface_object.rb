module ModelKit
    module Component
        # Base class for all objects that describe a {Node}'s interface
        class InterfaceObject
            # This object's node
            # @return [Node]
            attr_accessor :node
            # The property name
            # @return [String]
            attr_reader :name

            # Gets/sets a string describing this object
            #
            # @return [String]
            dsl_attribute(:doc) { |value| value.to_s }

            def initialize(node, name)
                @node = node
                @name = name.to_s
                @doc = nil
            end

            # Rebinds this object on another task, optionally renaming it, and
            # returns self
            def rebind(new_node, name: self.name)
                @node = new_node
                @name = name
                self
            end
        end
    end
end
