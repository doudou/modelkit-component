module ModelKit
    module Component
        # Specification for an output port
        class OutputPort < Port
            # @param (see Port#initialize)
            def initialize(node, name, type)
                super
                @sample_size  = 1
                @period = 1
                @burst_size   = 0
                @burst_period = 0
                @port_triggers = Set.new
                @triggered_on_update = nil
            end

            # Overloaded from {Port#output_port?} to mark that instances of this
            # class are outputs
            def output_port?
                true
            end

            # The size of a burst
            #
            # @return [Integer]
            # @see burst
            attr_reader :burst_size

            # Burst period
            #
            # @return [Integer]
            # @see burst
            attr_reader :burst_period

            # Sets and gets the sample size, i.e. how many data samples are
            # pushed at once to this port.
            #
            # @return [Integer]
            dsl_attribute(:sample_size) { |value| Integer(value) }

            # Sets the period for this output port, in cycles. The port period
            # should be the minimal amount of execution cycles (calls to
            # updateHook) between two updates of this port.
            #
            # It is useful only if 
            #
            # The default is one.
            #
            # @return [Period]
            dsl_attribute(:period) { |value| Integer(value) }

            # Declares that a burst of data can occasionally be written to this
            # port. +count+ is the maximal number of samples that are pushed to
            # this port at once, and +period+ how often this burst can happen.
            #
            # If the perid is set to 0, then it is assumed that the bursts
            # happen 'every once in a while', i.e. that it can be assumed that
            # the event is "rare enough".
            #
            # The default is no burst
            def burst(size, period: 1)
                @burst_size   = Integer(size)
                @burst_period = Integer(period)
                self
            end

            # The set of input ports that will cause a write on this output
            #
            # @return [Set<InputPort>]
            attr_reader :port_triggers

            # Declares that this port will be written whenever a sample is
            # received on the given input ports. The default is to consider that
            # the port is written whenever the node's update is called
            #
            # You must call #triggered_on_update explicitely if the port will
            # also be written for each update as well
            #
            # @param [String,InputPort] input_ports
            def triggered_on(*input_ports)
                if triggered_once_per_update?
                    raise Incompatibility, "a port cannot be triggered by input ports and have triggered_once_per_update? set at the same time"
                end

                input_ports = input_ports.map do |port_or_name|
                    if port_or_name.respond_to?(:to_str)
                        if !(p = node.find_input_port(port_or_name.to_str))
                            raise ArgumentError, "#{port_or_name} is not an input port of #{node}"
                        end
                        p
                    elsif port_or_name.node != node
                        raise ArgumentError, "#{port_or_name} is not an input port of #{node}"
                    elsif port_or_name.output_port?
                        raise ArgumentError, "#{port_or_name} is an output port of #{node}, cannot be used as a trigger"
                    else
                        port_or_name
                    end
                end

                @port_triggers |= input_ports
                self
            end

            # Tests whether this port is triggered by the arrival of data on
            # some input ports
            def has_port_triggers?
                !port_triggers.empty?
            end

            # Used to write the triggered_on_update flag directly. This should
            # not be used in normal situations
            attr_writer :triggered_on_update

            # Declares that this port will be written for each call within the
            # node's update routine
            #
            # It is the default if #triggered_on has not been called.
            def triggered_on_update
                @triggered_on_update = true
                self
            end

            # Declares that at most one sample will be written per call to
            # updateHook, regardless of the actual amount of samples that are
            # waiting to be read by the task
            def triggered_once_per_update
                if has_port_triggers?
                    raise Incompatibility, "an output port cannot be triggered by the node's update and by input ports at the same time"
                end
                @triggered_once_per_update = true
                self
            end

            # True if the port will be written for the calls to updateHook()
            # that are triggered by the activity.
            #
            # See #triggered_on_update and #triggered_on
            def triggered_on_update?
                if @triggered_once_per_update then true
                elsif !has_port_triggers?
                    # One can set triggered_on_update to false explicitely to
                    # override the default
                    @triggered_on_update != false
                else
                    @triggered_on_update
                end
            end

            # If true, this port will be written at most once per call to
            # updateHook, regardless of the actual amount of samples that are
            # waiting to be read by the task
            #
            # The port period and burst are still used
            def triggered_once_per_update?
                !!@triggered_once_per_update
            end
        end
    end
end


