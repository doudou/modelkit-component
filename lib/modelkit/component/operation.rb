module ModelKit
    module Component
        # Representation of an operation.
        #
        # Operations are procedure calls that are served by a {Node}
	class Operation
	    # The node this operation is part of
	    attr_reader :node
	    # The operation name
	    attr_reader :name
            # True if this operation runs in the caller's execution context, or
            # in the callee. The default is callee.
            #
            # See also #runs_in_caller_thread and #runs_in_callee_thread
            attr_reader :in_caller_thread

	    def initialize(task, name)
                name = name.to_s
		if name !~ /^\w+$/
                    raise ArgumentError, "#{self.class.name.downcase} names need to be valid C++ identifiers, i.e. contain only alphanumeric characters and _ (got #{name})"
		end

		@task = task
		@name = name
                @return_type = [nil, 'void', ""]
		@arguments = []
                @in_caller_thread = false
                @doc = nil

                super()
	    end

            # Declares that the C++ method associated with this operation should
            # be executed in the caller thread (default is callee thread)
            #
            # See also #runs_in_callee_thread and #in_caller_thread
            def runs_in_caller_thread
                @in_caller_thread = true
                self
            end

            # Declares that the C++ method associated with this operation should
            # be executed in the caller thread
            #
            # See also #runs_in_callee_thread and #in_caller_thread
            def runs_in_callee_thread
                @in_caller_thread = false
                self
            end

	    # call-seq:
	    #	doc new_doc -> self
            #	doc ->  current_doc
	    #
	    # Gets/sets a string describing this object
	    dsl_attribute(:doc) { |value| value.to_s }

	    # The set of arguments of this operation, as an array of [name, type,
	    # doc] elements. The +type+ objects are Types::Type instances.
            # 
            # See #argument
	    attr_reader :arguments

            # This version of find_interface_type returns both a Types::Type object and
            # a normalized version for +name+. It does accept const and
            # reference qualifiers in +name+.
            def find_interface_type(qualified_type)
                if qualified_type.respond_to?(:name)
                    qualified_type = qualified_type.name
                end
                type_name = ModelKit.unqualified_cxx_type(qualified_type)
                typelib_type_name = ::Types::GCCXMLLoader.cxx_to_typelib(type_name)
		type      = task.project.find_interface_type(typelib_type_name)
                ModelKit.validate_toplevel_type(type)
                return type, qualified_type.gsub(type_name, type.cxx_name)
            end

            # Defines the next argument of this operation.
            #
            # @param [String] name the argument name
            # @param [Model<Types::Type>,String] type the argument type either
            #   as a type object or as a type name that can be resolved on the
            #   underlying node's loader
            # @param [String] doc the argument documentation
	    def argument(name, qualified_type, doc = "")
                type, qualified_type = find_interface_type(qualified_type)
		arguments << [name, type, doc, qualified_type]
		self
	    end

	    # The return type of this operation
            #
            # @return [(Model<Types::Type>,String)] the return type and the
            #   associated documentation. The type is {VoidType} if the
            #   operation does not return anything.
            # @see #returns
	    attr_reader :return_type

            # Sets the return type for this operation
            #
            # @param [Model<Types::Type>,String] type the argument type either
            #   as a type object or as a type name that can be resolved on the
            #   underlying node's loader
            # @param [String] doc documentation about the returned value
	    def returns(type, doc = "")
                @return_type = 
		self
	    end

            # Declares that this operation does not return anything
            def returns_nothing
                returns(VoidType)
            end

            # Tests whether this operation returns anything
            def returns?
                @return_type[0] != VoidType
            end

            # Returns true if this operation's signature is not void
            def has_return_value?
                !!@return_type.first
            end

            def pretty_print(pp)
                pp.text name
                pp.nest(2) do
                    if !self.doc
                        pp.breakable
                        pp.text self.doc
                    end
                    if !self.return_type[2].empty?
                        pp.breakable
                        pp.text "Returns: #{self.return_type[2]}"
                    end
                    arguments.map do |name, type, doc, qualified_type|
                        pp.breakable
                        pp.text "#{name}: #{doc}"
                    end
                end
            end

            attr_predicate :hidden?, true
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
                    result[:returns] = Hash[type: self.return_type[0].to_h, doc: self.return_type[2]]
                end
                result[:arguments] = arguments.map do |name, type, doc, qualified_type|
                    Hash[name: name, type: type.to_h, doc: doc]
                end
                result
            end
	end
    end
end


