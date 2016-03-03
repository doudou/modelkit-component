module ModelKit
    module Component
        # A typekit, i.e. a subpart of the system that handles a set of types
        class Typekit
            # The underlying loader
            attr_reader :loader

            # The typekit name
            attr_reader :name

            # The typekit's type registry
            attr_reader :registry

            # The subset of known types that are defined by this typekit. Other
            # types are expected to be imported from other typekits
            #
            # @return [Set]
            attr_reader :typelist

            # The subset of known types that are defined by this typekit and can
            # be used on node interfaces.
            #
            # @return [Set]
            attr_reader :interface_typelist

            def initialize(loader, name: nil, registry: Types::Registry.new,
                           typelist: Set.new, interface_typelist: Set.new)
                @loader = loader
                @name = name
                @registry = registry
                @typelist = typelist.to_set
                @interface_typelist = interface_typelist.to_set
            end

            # The set of type models that are defined by this typekit
            def self_types
                typelist
            end

            # Registers this type as a type that is defined by self
            def register_type(type)
                typelist << type
            end

            # Registers this type as a type that is defined by self and that can
            # be used on an interface
            def register_interface_type(type)
                register_type(type)
                interface_typelist << type
            end

            # Tests whether this typekit defines at least one array of the given
            # type
            #
            # @param [Type] type
            def defines_array_of?(type)
                type = resolve_type(type)
                typelist.any? { |t| (t <= ModelKit::Types::ArrayType) && (t.deference == type) }
            end

            # Tests whether a type is defined by this typekit
            #
            # @param [String,#name] type
            def include?(type)
                typelist.include?(resolve_type(type))
            rescue ModelKit::Types::NotFound
                false
            end

            # Tests whether a type is defined by this typekit, and is an
            # interface type
            #
            # @param [String,#name] type
            def interface_type?(type)
                interface_typelist.include?(resolve_type(type))
            rescue ModelKit::Types::NotFound
                false
            end

            # Returns a matching type in {#registry}
            #
            # @param [#name,String] type
            # @return [Model<Types::Type>]
            # @raise Types::NotFound
            def resolve_type(type)
                typename = if type.respond_to?(:name) then type.name
                           else type.to_str
                           end
                registry.get(typename)
            end

            def inspect
                "#<ModelKit::Component::Typekit #{name}>"
            end

            def respond_to_missing?(m, include_private = false)
                if super then return super
                elsif m.to_s =~ /^create_(interface_)?(\w+)$/
                    registry.respond_to?("create_#{$2}")
                end
            end

            # Adds to the API of self the create_* methods on Types::Registry.
            # All create_ methods are available, as well as the corresponding
            # create_interface_XXX which both creates the type and declares it
            # as a valid interface type
            #
            # @example create a null type
            #   typekit.create_interface_null('/NewType')
            def method_missing(m, *args, &block)
                case m.to_s
                when /^create_(interface_)?(\w+)$/
                    interface = !!$1
                    category  = $2
                    type = registry.send("create_#{category}", *args, &block)
                    if interface
                        register_interface_type(type)
                    else
                        register_type(type)
                    end
                    type
                else super
                end
            end
        end
    end
end

