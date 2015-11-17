module ModelKit
    module Component
        # Model of an input port
        class InputPort < Port
            # Create an input port
            #
            # @param (see Port#initialize)
	    def initialize(node, name, type)
                super
                @needs_reliable_connection = false
                @clean_on_node_start = false
                @multiplexes = false
            end

            # Overloaded from {Port#output_port?} to mark that instances of this
            # class are outputs
            def output_port?
                false
            end

            # Returns true if the underlying node requires connections to this
            # port to be reliable (i.e. non-lossy).
            #
            # @see needs_reliable_connection
            def needs_reliable_connection?
                @needs_reliable_connection
            end

            # Declares that the node requires a non-lossy connection towards
            # this port
            #
            # @return [self]
            def needs_reliable_connection
                @needs_reliable_connection = true
                self
            end

            # Control whather samples present but unread on this port should be
            # cleaned when the node is started
            #
            # The default is to clean the port, call this to disable the
            # behaviour
            #
            # @return [self]
            def do_not_clean_on_node_start
                @clean_on_node_start = false
                self
            end

            # Whether samples present but unread on this port will be cleaned on
            # startup
            #
            # @see do_not_clean_on_node_start
            def clean_on_node_start?
                @clean_on_node_start
            end

            # If true, this port accepts to have multiple active connections at the same time
            #
            # The default is for ports to not accept multiplexing
            #
            # @see multiplexes
            def multiplexes?
                @multiplexes
            end

            # Declares that this port accepts multiple active connections
            #
            # @see multiplexes?
            # @return [self]
            def multiplexes
                @multiplexes = true
                self
            end
        end
    end
end

