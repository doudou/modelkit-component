require 'test_helper'

describe ModelKit::Component::Deployment::Node do
    attr_reader :project, :task_model, :deployment
    before do
        loader = ModelKit::Component::Loaders::Files.new
        ModelKit::Component::Loaders::RTT.setup_loader(loader)
        @project    = ModelKit::Component::Project.new(loader)
        @project.name 'test'
        @task_model = project.task_context 'Test'
        @deployment = project.deployment 'test'
    end

    it "allows to change a default activity" do
        task_model.default_activity :periodic, 0.1
        task = deployment.task "my_name", task_model
        task.triggered
        assert_equal("RTT::Activity", task.activity_type.class_name)
        assert_equal(0, task.period)
    end

    it "raises ArgumentError if trying to change a required activity" do
        task_model.required_activity :periodic, 0.1
        task       = deployment.task "my_name", task_model
        assert_raises(ArgumentError) { task.triggered }
    end

    it "raises ArgumentError if trying to change an already explicitly set activity" do
        task = deployment.task "my_name", task_model
        task.triggered
        assert_raises(ArgumentError) { task.periodic(0.1) }
    end
end

