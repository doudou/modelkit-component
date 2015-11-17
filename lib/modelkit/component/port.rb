module ModelKit
    module Component
        # Generic representation of ports. The actual ports are either
        # instance of InputPort or OutputPort
        class Port
            # The port task
            attr_reader :node
            # The port name
            attr_reader :name
            # The port type
            attr_reader :type

            # Converts this model into a representation that can be fed to e.g.
            # a JSON dump, that is a hash with pure ruby key / values.
            #
            # The generated hash has the following keys:
            #
            #     name: the name
            #     type: the type (as marshalled with Types::Type#to_h)
            #     direction: either the string 'input' or 'output'
            #     doc: the documentation string
            #
            # @return [Hash]
            def to_h
                direction = if output_port? then 'output'
                            else 'input'
                            end

                Hash[
                    direction: direction,
                    name: name,
                    type: type.to_h,
                    doc: (doc || "")
                ]
            end

            # Whether this port is an output port
            #
            # Note that if false, the port is automatically an input port
            def output_port?
                raise NotImplementedError, "output_port? must be overloaded in subclasses"
            end

            # True if the node requires to be stopped to change this port's
            # connection
            #
            # @see #static
            def static_connections?; !!@static end

            # Declares that this port can be connected/disconnected only when
            # the node is in a non-running state.
            #
            # The default is that the port is dynamic, i.e. can be
            # connected/disconnected regardless of the node's state.
            #
            # See also #dynamic
            def static_connections; @static = true end

            # Declares that this port can be connected/disconnected while the
            # task context is running. It is the opposite of #static.
            #
            # This is the default
            def dynamic_connections; @static = false end

            # True if this is a dynamic port model, false otherwise
            #
            # Dynamic ports are ports that can be created by the node (the
            # protocol for doing so being node-specific).
            #
            # @see Node#dynamic_input_port and Node#dynamic_output_port
            def dynamic?; false end

            def pretty_print(pp)
                direction = if output_port? then 'out'
                            else 'in'
                            end
                pp.text "[#{direction}]#{name}:#{type.name}"
            end

            def initialize(node, name, type)
                type = node.project.find_interface_type(type)
                @node, @name, @type = node, name, type

                @doc = nil
            end

            # Gets/sets a string describing this object
            #
            # @return [String]
            dsl_attribute(:doc) { |value| value.to_s }
        end
    end
end


