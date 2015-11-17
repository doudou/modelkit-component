describe ModelKit::Component::Deployment::Container do
    attr_reader :project, :task_model, :deployment
    before do
        loader   = ModelKit::Component::Loaders::Files.new
        @project = ModelKit::Component::Project.new(loader)
        @project.name 'test'
        @task_model = project.task_context 'Test'
        @deployment = project.deployment 'test'
    end

    describe "#activity_ordered_tasks" do
        it "is well-behaved if there are no tasks in the deployment" do
            assert_equal Array.new, deployment.activity_ordered_tasks
        end
        it "places masters before the slaves" do
            slave = deployment.task('slave', task_model)
            master = deployment.task('master', task_model)
            deployment.set_master_slave_activity master, slave
            assert_equal [master, slave], deployment.activity_ordered_tasks
        end
        it "raises InternalError if there is a loop" do
            t0 = deployment.task('t0', task_model)
            t1 = deployment.task('t1', task_model)
            deployment.set_master_slave_activity t0, t1
            deployment.set_master_slave_activity t1, t0

            assert_raises(ArgumentError) { deployment.activity_ordered_tasks }
        end
    end

    describe "#task" do
        it "sets the task name to the given name" do
            task = deployment.task('task', 'Test')
            assert_equal 'task', task.name
        end
        it "sets the task model to the given model" do
            task = deployment.task('task', 'Test')
            assert_equal task_model, task.task_model
        end
        it "accepts a task model by object" do
            task = deployment.task('task', task_model)
            assert_equal task_model, task.task_model
        end
        it "raises ArgumentError if the model name cannot be resolved" do
            assert_raises(ModelKit::Component::TaskModelNotFound) { deployment.task "name", "Bla" }
        end
        it "raises ArgumentError if a task with the given name already exists" do
            deployment.task('task', task_model)
            assert_raises(ArgumentError) { deployment.task "task", task_model }
        end
        it "sets the deployed task's activity to the default" do
            task_model.default_activity :periodic, 0.1
            task = deployment.task "test", task_model
            assert_equal("RTT::Activity", task.activity_type.class_name)
            assert_equal(0.1, task.period)
        end
    end
end

