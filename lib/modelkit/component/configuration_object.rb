module ModelKit
    module Component
        # Representation of a task's attribute or property
	class ConfigurationObject
            # The component on which this property is attached
            attr_accessor :component
	    # The property name
	    attr_reader :name

	    # The property type, as a ModelKit::Types::Type object from the underlying
	    # project's type registry
	    attr_reader :type

            # Whether this configuration object can be set dynamically
            attr_predicate :dynamic?, true

	    # The property's default value
            #
            # @return [Model<Types::Type>]
	    attr_reader :default_value

	    # Create a new property with the given name, type and default value
	    def initialize(component, name, type, default_value: nil)
                name = name.to_s
                type = component.project.resolve_type(type)
                @dynamic = false
		@component, @name, @type, @default_value = component, name, type, default_value
                @doc = nil
	    end

            def dynamic
                @dynamic = true
                self
            end

            def pretty_print(pp)
                default = if value = self.default_value
                              ", default: #{value}"
                          end

                if doc
                    first_line = true
                    doc.split("\n").each do |line|
                        pp.breakable if !first_line
                        first_line = false
                        pp.text "# #{line}"
                    end
                    pp.breakable
                end
                pp.text "#{name}:#{type.name}#{default}"
            end

	    # call-seq:
	    #	doc new_doc -> self
            #	doc ->  current_doc
	    #
	    # Gets/sets a string describing this object
	    dsl_attribute(:doc) { |value| value.to_s }

            # Converts this model into a representation that can be fed to e.g.
            # a JSON dump, that is a hash with pure ruby key / values.
            #
            # The generated hash has the following keys:
            #
            #     name: the attribute name
            #     type: the type (as marshalled with Types::Type#to_h)
            #     dynamic: boolean value indicating whether this can be set
            #       dynamically or not
            #     doc: the documentation string
            #     default: the default value. Not present if there is none.
            #
            # @return [Hash]
            def to_h
                result = Hash[
                    name: name,
                    type: type.to_h,
                    dynamic: !!dynamic?,
                    doc: (doc || "")]
                if value = self.default_value
                    if value.respond_to?(:to_simple_value)
                        result[:default] = value.to_simple_value
                    else
                        result[:default] = value
                    end
                end
                result
            end
	end
    end
end

