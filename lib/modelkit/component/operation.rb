module ModelKit
    module Component
        # Representation of an operation.
        #
        # Operations are procedure calls that are served by a {Node}
        class Operation
            class DuplicateArgument < ArgumentError; end

            # The node this operation is part of
            attr_reader :node
            # The loader used to resolve argument and return types
            attr_reader :loader
            # The operation name
            attr_reader :name
            # True if this operation runs in the callee's execution context, or
            # outside of it. The default is callee.
            attr_predicate :in_callee_thread?
            # Whether this operation is defined for the benefit of the
            # component's user (false) or for the framework's (true)
            attr_predicate :hidden?, true

            # @!method doc
            #   @return self
            # @!method doc(string)
            #   @return [String]
            #
            # Gets/sets a string describing this object
            dsl_attribute(:doc) { |value| value.to_s }

            Argument   = Struct.new :name, :type, :doc

            # The set of arguments of this operation, as an array of [name, type,
            # doc] elements. The +type+ objects are Types::Type instances.
            # 
            # @return [Array<Argument>]
            attr_reader :arguments

            ReturnValue = Struct.new :type, :doc

            # The description of this operation's returned value
            #
            # @return [ReturnValue] the return type and the
            #   associated documentation. {ReturnValue#type} is {VoidType} if
            #   the operation does not return anything.
            # @see #returns
            attr_reader :return_value

            def initialize(node, name)
                @node = node
                @name = name.to_s
                @loader = node.loader
                @return_value = ReturnValue.new(VoidType, nil)
                @arguments = []
                @in_callee_thread = true
                @doc = nil

                super()
            end

            # Declares that the operation is executed outside the callee's
            # execution context
            def runs_outside_callee_thread
                @in_callee_thread = false
                self
            end

            # Declares that the operation is executed within the callee's
            # execution context
            def runs_in_callee_thread
                @in_callee_thread = true
                self
            end

            # Defines the next argument of this operation.
            #
            # @param [String] name the argument name
            # @param [Model<Types::Type>,String] type the argument type either
            #   as a type object or as a type name that can be resolved on the
            #   underlying node's loader
            # @param [String] doc the argument documentation
            def argument(name, type, doc = nil)
                type = loader.resolve_interface_type(type)
                if arguments.any? { |a| a.name == name }
                    raise DuplicateArgument, "#{self} already has an argument named #{name}"
                end
                arguments << Argument.new(name, type, doc)
                self
            end

            # Finds an argument by name
            #
            # @return [Argument,nil]
            def find_argument_by_name(name)
                arguments.find { |a| a.name == name }
            end

            # Sets the return type for this operation
            #
            # @param [Model<Types::Type>,String] type the argument type either
            #   as a type object or as a type name that can be resolved on the
            #   underlying node's loader
            # @param [String] doc documentation about the returned value
            def returns(type, doc = "")
                @return_value = ReturnValue.new(loader.resolve_interface_type(type), doc)
                self
            end

            # Declares that this operation does not return anything
            def returns_nothing
                @return_value = ReturnValue.new(VoidType, nil)
                self
            end

            # Tests whether this operation returns anything
            def has_return_value?
                @return_value.type != VoidType
            end

            def pretty_print(pp)
                pp.text "#{name}:"
                pp.nest(2) do
                    if doc
                        pp.breakable
                        pp.text ": #{doc}"
                    end
                    if has_return_value?
                        pp.breakable
                        pp.text "Returns: #{self.return_value.type} (#{self.return_value.doc}"
                    end
                    arguments.map do |arg|
                        pp.breakable
                        pp.text "#{arg.name}: #{arg.type} (#{arg.doc})"
                    end
                end
            end

            # Converts this model into a representation that can be fed to e.g.
            # a JSON dump, that is a hash with pure ruby key / values.
            #
            # The generated hash has the following keys:
            #
            #     name: the operation name
            #     returns: the operation return type. It is not present if the
            #       operation does not return anything
            #         type: the return type as marshalled with
            #           Types::Type#to_h
            #         doc: the return type documentation
            #
            #     arguments: the list of arguments as an array of
            #         name: the argument name
            #         type: the argument type as marshalled with
            #           Types::Type#to_h
            #         doc: the argument documentation
            #
            # @return [Hash]
            def to_h
                result = Hash[name: name, doc: (doc || "")]
                if has_return_value?
                    result[:returns] = Hash[type: self.return_value.type.to_h, doc: (self.return_value.doc || '')]
                end
                result[:arguments] = arguments.map do |arg|
                    Hash[name: arg.name, type: arg.type.to_h, doc: (arg.doc || '')]
                end
                result
            end
        end
    end
end


