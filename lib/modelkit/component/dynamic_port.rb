module ModelKit
    module Component
        # @api private
        #
        # Common functionality between {DynamicInputPort} and
        # {DynamicOutputPort}
        module DynamicPort
            attr_reader :name
            attr_reader :pattern

            def initialize(node, name, type: VoidType, pattern: nil)
                super(node, name, type)
                @pattern = pattern
            end

            def any_type?
                type.null?
            end

            def instanciate(name, type = nil)
                if pattern && (pattern !~ name)
                    raise ArgumentError, "attempting to instanciate #{self} using name #{name} but #{name} does not match the expected pattern #{pattern}"
                end

                if type
                    type = node.loader.resolve_interface_type(type)
                    if self.type && (type != self.type)
                        raise ArgumentError, "cannot instanciate #{self} with type #{type} as #{self.type} was specified"
                    end
                elsif any_type?
                    raise ArgumentError, "no type given, but #{self} has not type itself"
                end

                m = dup
                m.instance_variable_set :@name, name
                m.instance_variable_set :@type, type || self.type
                m
            end

            def dynamic?; true end

            def pretty_print(pp)
                pp.text "[dyn,#{self.class < InputPort ? "in" : "out"}]#{name}:#{if type then type.name else "any type" end}"
            end
        end
    end
end


