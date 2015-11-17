module ModelKit
    module Component
        module Deployment
            # Aggregation of deployed {Component}, usually but not
            # necessarily the representation of a process
            class Container
                # The deployment name
                attr_reader :name
                # The underlying {Project} object
                attr_reader :project
                # The set components that are aggregated within this container
                attr_reader :components

                def initialize(project, name)
                    @project  = project
                    @name     = name

                    @components = Array.new
                end

                def initialize_copy(old)
                    super
                    @components = @components.dup
                end

                # Deploys a new component using the given component model, and
                # returns the corresponding {Component} object. This instance
                # can be used to configure the task further (for instance
                # specifying the activity).
                #
                # @param [String] name the name of the deployed component
                # @param [Component::Component] the component model
                # @see Component
                def component(name, klass)
                    if klass.respond_to?(:to_str)
                        task_context = project.task_model_from_name(klass)
                    else task_context = klass
                    end

                    if find_task_by_name(name)
                        raise ArgumentError, "there is already a task #{name} on the deployment #{self.name}"
                    end
                    deployment = TaskDeployment.new(name, task_context)
                    task_activities << deployment
                    deployment
                end

                # Enumerates the tasks defined on this deployment
                #
                # @yieldparam [TaskDeployment] task a deployed task
                def each_task(&block)
                    task_activities.each(&block)
                end

                # Returns the deployed task that has this name
                #
                # @return [TaskDeployment,nil] the deployed task model, or nil if
                #   none exists with that name
                def find_task_by_name(name)
                    task_activities.find { |act| act.name == name }
                end

                # True if this deployment should export its tasks through CORBA.
                #
                # It is true by default if the CORBA transport is enabled
                def corba_enabled?
                    if @corba_enabled.nil?
                        transports.include?('corba')
                    else @corba_enabled
                    end
                end

                # Force disabling CORBA support even though the CORBA transport is
                # enabled in this deployment
                #
                # See #corba_enabled?
                def disable_corba; @corba_enabled = false end

                # Force enabling CORBA support even though the CORBA transport is
                # not enabled in this deployment
                #
                # See #corba_enabled?
                def enable_corba; @corba_enabled = true end

                #handels theActivity creation order to be sure that all activities are created in the right order
                def activity_ordered_tasks(ordered=Array.new)
                    oldsize = ordered.size()
                    (task_activities - ordered).each do |task|
                        if !task.master || ordered.include?(task.master)
                            ordered << task
                        end
                    end
                    if ordered.size == task_activities.size
                        return ordered
                    elsif oldsize == ordered.size()
                        activities = task_activities.map do |task|
                            "\n  #{task.name} (master: #{task.master ? task.master.name : "none"})"
                        end
                        raise ArgumentError, "I cannot find an order in which to create the deployed tasks of #{name} during deployment" <<
                            "Did you created a loop among master and slave activities ?. The #{activities.size} deployed tasks are:#{activities.join("\n  ")}"
                    else
                        return activity_ordered_tasks(ordered)
                    end
                end

                # Define an master slave avtivity between tasks
                def set_master_slave_activity(master, slave)
                    slave.slave_of(master)
                    self
                end

                dsl_attribute :main_task do |task|
                    @main_task = task
                end

                def add_default_logger
                    project.using_task_library "logger"
                    task("#{name}_Logger", 'logger::Logger')
                end

                # The set of peer pairs set up for this deployment. This is a set
                # of [a, b] TaskDeployment objects.
                attr_reader :peers

                # The set of connections set up for this deployment. This is a set
                # of [from, to] PortDeployment objects.
                attr_reader :connections

                # Connects the two given ports or tasks
                def connect(from, to, policy = Hash.new)
                    add_peers from.activity, to.activity

                    if from.kind_of?(Port)
                        if !from.kind_of?(OutputPort)
                            raise ArgumentError, "in connect(a, b), 'a' must be a writer port"
                        elsif !to.kind_of?(InputPort)
                            raise ArgumentError, "in connect(a, b), 'b' must be a reader port"
                        end
                    end

                    connections << [from, to, ConnPolicy.from_hash(policy)]
                    self
                end

                # Declare that the given tasks are peers
                def add_peers(a, b)
                    peers << [a, b]
                    self
                end

                # call-seq:
                #   browse -> currently_browsed_task
                #   browse(task) -> self
                #
                # Sets up a TaskBrowser to browse the given task, which
                # is started when all tasks have been initialized. This is incompatible
                # with the use of CORBA and only one browser can be defined.
                dsl_attribute :browse do |task|
                    if browse
                        raise ArgumentError, "can browse only one task"
                    elsif corba_enabled?
                        raise ArgumentError, "cannot browse and use CORBA at the same time"
                    end
                    @browse = task
                end

                def get_lock_timeout_no_period
                    @lock_timeout_no_period
                end

                # Set the lock timeout of a thread, which has no period
                # if set, the minimum setting is 1s
                def lock_timeout_no_period(timeout_in_s)
                    @lock_timeout_no_period = [1,timeout_in_s].max
                end

                def get_lock_timeout_period_factor
                    @lock_timeout_period_factor
                end

                # Set the mutex timeout for a thread with a given period 
                # by a factor of its period
                # if set, the minimum setting is factor 10 (times the period)
                def lock_timeout_period_factor(factor)
                    @lock_timeout_period_factor = [10,factor.to_i].max
                end

                # Displays this deployment's definition nicely
                def pretty_print(pp) # :nodoc:
                    pp.text "------- #{name} ------"
                    pp.breakable
                    if !task_activities.empty?
                        pp.text "Tasks"
                        pp.nest(2) do
                            pp.breakable
                            pp.seplist(task_activities) do |act|
                                act.pretty_print(pp)
                            end
                        end
                    end

                    if !connections.empty?
                        pp.breakable if !task_activities.empty?
                        pp.text "Connections"
                        pp.nest(2) do
                            pp.breakable
                            pp.seplist(connections) do |conn|
                                from, to, policy = *conn
                                pp.text "#{from.activity.name} => #{to.activity.name} [#{policy.inspect}]"
                            end
                        end
                    end
                end
            end
        end
    end
end


