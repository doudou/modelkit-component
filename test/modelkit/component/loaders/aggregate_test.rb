require 'test_helper'

module ModelKit::Component
    module Loaders
        describe Aggregate do
            attr_reader :aggregate, :base
            before do
                @aggregate = Aggregate.new
                @base = Base.new(aggregate)
            end

            it "raises on #add if the loader is already present" do
                assert_raises(DuplicateLoader) do
                    aggregate.add base
                end
            end

            it "can deregister loaders" do
                aggregate.remove base
                assert_equal [], aggregate.loaders
            end

            def self.common_query_tests(d, query_method, not_found, &block)
                d.it "returns a child's object" do
                    flexmock(base).should_receive(query_method).with('test').
                        and_return(obj = instance_eval(&block))
                    assert_same obj, aggregate.send(query_method, 'test')
                end
                d.it "ignores children whose query method raises #{not_found}" do
                    loader_without = Base.new(aggregate)
                    flexmock(base).should_receive(query_method).with('test').
                        and_return(obj = instance_eval(&block))

                    assert_same obj, aggregate.send(query_method, 'test')
                end
                d.it "raises ProjectNotFound if it has no children" do
                    assert_raises(not_found) do
                        aggregate.send(query_method, 'test')
                    end
                end
                d.it "raises ProjectNotFound if all its children do" do
                    flexmock(base).should_receive(query_method).with('test').
                        and_raise(not_found)
                    assert_raises(not_found) do
                        aggregate.send(query_method, 'test')
                    end
                end
            end

            describe "#project_model_from_name" do
                common_query_tests(self, :project_model_from_name, ProjectNotFound) do
                    flexmock
                end

                it "caches projects registered on the child loader" do
                    base.register_project_model(obj = Project.new(base, name: 'test'))
                    flexmock(base, :strict).should_receive(:project_model_from_name).never
                    assert_same obj, aggregate.project_model_from_name('test')
                end
            end

            describe "#typekit_model_from_name" do
                common_query_tests(self, :typekit_model_from_name, TypekitNotFound) do
                    flexmock
                end

                it "caches typekits registered on the child loader" do
                    base.register_typekit_model(obj = Typekit.new(base, name: 'test'))
                    flexmock(base, :strict).should_receive(:typekit_model_from_name).never
                    assert_same obj, aggregate.typekit_model_from_name('test')
                end
            end

            describe "#node_model_from_name" do
                common_query_tests(self, :node_model_from_name, NodeModelNotFound) do
                    flexmock
                end

                it "caches node models registered on the child loader" do
                    base.register_node_model(obj = Node.new_submodel(name: 'test'))
                    flexmock(base, :strict).should_receive(:node_model_from_name).never
                    assert_same obj, aggregate.node_model_from_name('test')
                end
            end

            describe "#deployment_model_from_name" do
                common_query_tests(self, :deployment_model_from_name, DeploymentModelNotFound) do
                    flexmock
                end

                it "caches deployment models registered on the child loader" do
                    base.register_deployment_model(obj = Deployment.new(base, name: 'test'))
                    flexmock(base, :strict).should_receive(:deployment_model_from_name).never
                    assert_same obj, aggregate.deployment_model_from_name('test')
                end
            end

            describe "#deployed_node_model_from_name" do
                common_query_tests(self, :deployed_node_model_from_name, DeployedNodeModelNotFound) do
                    flexmock
                end
            end
        end
    end
end
