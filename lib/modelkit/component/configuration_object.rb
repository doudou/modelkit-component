module ModelKit
    module Component
        # Representation of a task's attribute or property
        class ConfigurationObject < InterfaceObject
            # The property type, as a ModelKit::Types::Type object from the
            # underlying project's type registry
            #
            # @return [Model<Types::Type>]
            attr_reader :type

            # Whether this configuration object can be set dynamically
            attr_predicate :dynamic?, true

            # The property's default value
            #
            # @return [Types::Type]
            dsl_attribute :default_value

            # Create a new property with the given name, type and default value
            def initialize(node, name, type, default_value: nil)
                super(node, name)
                @dynamic = false
                @doc = nil

                @type = node.loader.resolve_interface_type(type)
                @default_value = ModelKit::Types.from_ruby(default_value, type)
            end

            # Declares that this object can be modified while the node is
            # running
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

            # Gets/sets a string describing this object
            # @return [String]
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

