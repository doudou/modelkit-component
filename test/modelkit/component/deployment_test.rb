require 'test_helper'

module ModelKit::Component
    describe Deployment do
        attr_reader :loader, :deployment
        before do
            @loader = Loaders::Base.new
            @deployment = Deployment.new(loader)
        end

        it "registers the new deployed node" do
            node_m = Node.new_submodel(name: 'Test')
            deployed_node = deployment.node('test', node_m)
            assert_same deployed_node, deployment.deployed_node_from_name('test')
        end

        it "raises if the deployed node's name is already taken" do
            node_m = Node.new_submodel(name: 'Test')
            deployed_node = deployment.node('test', node_m)
            assert_raises(ArgumentError) do
                deployment.node('test', node_m)
            end
            assert_same deployed_node, deployment.deployed_node_from_name('test')
        end

        it "registers a deployed node by model" do
            node_m = Node.new_submodel(name: 'Test')
            deployed_node = deployment.node('test', node_m)
            assert_equal 'test', deployed_node.name
            assert_same node_m, deployed_node.model
        end

        it "resolves a node model given its name" do
            node_m = Node.new_submodel(name: 'Test')
            loader.register_node_model(node_m)
            deployed_node = deployment.node('test', 'Test')
            assert_equal 'test', deployed_node.name
            assert_same node_m, deployed_node.model
        end
    end
end
