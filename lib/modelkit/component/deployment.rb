module ModelKit
    module Component
        module Deployment
            class << self
                # Default minimal latency value used for realtime scheduling
                #
                # See TaskDeployment::minimal_trigger_latency
                attr_accessor :default_rt_minimal_trigger_latency
                # Default expected latency value used for realtime scheduling
                #
                # See TaskDeployment::worstcase_trigger_latency
                attr_accessor :default_rt_worstcase_trigger_latency
                
                # Default minimal latency value used for non-realtime scheduling
                #
                # See TaskDeployment::minimal_trigger_latency
                attr_accessor :default_nonrt_minimal_trigger_latency
                # Default expected latency value used for non-realtime scheduling
                #
                # See TaskDeployment::worstcase_trigger_latency
                attr_accessor :default_nonrt_worstcase_trigger_latency
            end
            
            @default_rt_minimal_trigger_latency = 0.001
            @default_rt_worstcase_trigger_latency = 0.005
            
            @default_nonrt_minimal_trigger_latency = 0.005
            @default_nonrt_worstcase_trigger_latency = 0.020
        end
    end
end

require 'modelkit/component/deployment/node'
require 'modelkit/component/deployment/container'

