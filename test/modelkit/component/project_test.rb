require 'test_helper'

module ModelKit::Component
    describe Project do
        attr_reader :project, :loader
        before do
            @loader = Loaders::Base.new
            @project = Project.new(loader)
        end

        describe "#node" do
            it "sets the name to the given name" do
                task = project.node 'Task'
                assert_equal 'Task', task.name
            end
            it "uses the project's default supermodel by default" do
                project.default_node_supermodel = m = Node.new_submodel
                node_m = project.node 'Task'
                assert_equal m, node_m.superclass
            end
            it "raises ArgumentError if the node's name already exists" do
                project.node 'Task'
                assert_raises(ArgumentError) { project.node 'Task' }
            end
        end

        describe "#version" do
            it "sets the project's version and returns self" do
                assert_same project, project.version('0.1')
            end
            it "returns the current project version" do
                project.version('0.1')
                assert_equal '0.1', project.version
            end
            it "raises ArgumentError if the version does not start with a number" do
                assert_raises(ArgumentError) do
                    project.version('a')
                end
            end
        end

        describe "#use_nodes_from" do
            it "makes the tasks of the node library object available to the project" do
                other_p = Project.new(loader)
                test_node = other_p.node 'Test'
                project.use_nodes_from other_p
                assert_same test_node, project.node_model_from_name('Test')
            end

            it "resolves the node library by name" do
                other_p = Project.new(loader, name: 'test')
                test_node = other_p.node 'Test'
                project.loader.register_project_model(other_p)

                project.use_nodes_from 'test'
                assert_same test_node, project.node_model_from_name('Test')
            end
        end

        describe "#use_types_from" do
            it "makes the types of the typekit object available to the project" do
                typekit = Typekit.new(loader)
                test_t = typekit.create_null '/test'
                project.use_types_from typekit
                assert_equal test_t, project.loader.resolve_type('/test')
            end

            it "resolves the typekit by name" do
                typekit = Typekit.new(loader, name: 'Test')
                test_t = typekit.create_null '/test'
                project.loader.register_typekit_model(typekit)

                project.use_types_from 'Test'
                assert_equal test_t, project.loader.resolve_type('/test')
            end
        end

        describe "#deployment" do
            it "creates, registers and returns a new deployment model" do
                yield_self = nil
                deployment_m = project.deployment 'test' do
                    yield_self = self
                end
                assert_kind_of Deployment, deployment_m
                assert_same deployment_m, yield_self
                assert_same deployment_m, project.deployment_model_from_name('test')
            end

            it "raises if the name is already taken" do
                deployment_m = project.deployment 'test'
                assert_raises(ArgumentError) do
                    project.deployment 'test'
                end
                assert_same deployment_m, project.deployment_model_from_name('test')
            end

            it "uses its supermodel argument as the deployment model's class" do
                klass = Class.new(Deployment)
                deployment_m = project.deployment 'test', supermodel: klass
                assert_kind_of klass, deployment_m
            end
        end

        describe "#has_deployment_model?" do
            it "returns true for an existing deployment" do
                project.deployment 'test'
                assert project.has_deployment_model?('test')
            end
            it "returns false for a non-existent deployment" do
                assert !project.has_deployment_model?('does_not_exist')
            end
        end

        it "can pretty-print itself" do
            project.node 'Test'
            project.pretty_print(PP.new(''))
        end

        it "can be printed" do
            project.to_s
        end
    end
end

