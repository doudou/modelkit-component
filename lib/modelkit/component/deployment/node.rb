module ModelKit
    module Component
        module Deployment
            # Deployed version of a {Component::Node}
            class Node
                # The deployed component name
                attr_accessor :name
                # The {Component::Node} model that is being deployed
                attr_reader :node_model

                # Overrides the default minimal trigger latency for this
                # particular task
                #
                # @see minimal_trigger_latency
                attr_writer :minimal_trigger_latency

                # Overrides the default expected trigger latency for this particular
                # task
                #
                # @see worstcase_trigger_latency
                attr_writer :worstcase_trigger_latency
                
                # Returns the minimal latency between the time the task gets
                # triggered (for instance because of data on an input event port),
                # and the time updateHook() is actually called, based on its
                # scheduler and priority. All tasks will return a value (even
                # non-periodic ones).
                #
                # Default values are set in the DEFAULT_RT_MINIMAL_TRIGGER_LATENCY
                # and DEFAULT_NONRT_MINIMAL_TRIGGER_LATENCY constants. They can be
                # overriden by setting the minimal_trigger_latency property
                def minimal_trigger_latency
                    if @minimal_trigger_latency
                        @minimal_trigger_latency
                    elsif realtime?
                        Deployment.default_rt_minimal_trigger_latency
                    else
                        Deployment.default_nonrt_minimal_trigger_latency
                    end
                end

                # Returns the expected (average) latency between the time the task
                # gets triggered (for instance because of data on an input event
                # port), and the time updateHook() is actually called, based on its
                # scheduler and priority. All tasks will return a value (even
                # non-periodic ones).
                #
                # Default values are set in the DEFAULT_RT_WORSTCASE_TRIGGER_LATENCY
                # and DEFAULT_NONRT_WORSTCASE_TRIGGER_LATENCY constants. They can be
                # overriden by setting the worstcase_trigger_latency property
                def worstcase_trigger_latency
                    computation_time = task_model.worstcase_processing_time || 0

                    trigger_latency =
                        if @worstcase_trigger_latency
                            @worstcase_trigger_latency
                        elsif @realtime
                            Deployment.default_rt_worstcase_trigger_latency
                        else
                            Deployment.default_nonrt_worstcase_trigger_latency
                        end
                    [computation_time, trigger_latency].max
                end

                def initialize(name, component)
                    @name       = name
                    @task_model = component
                end
            end
        end
    end
end


