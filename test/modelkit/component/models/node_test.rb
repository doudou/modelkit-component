require 'test_helper'

module ModelKit::Component
    module Models
        describe Node do
            attr_reader :node, :int_t, :double_t
            before do
                @int_t = create_dummy_interface_type '/int'
                @double_t = create_dummy_interface_type '/double'
                @node = ModelKit::Component::Node.new_submodel(project: dummy_project)
            end

            describe "#attribute" do
                it "should not allow for duplicate names" do
                    node.attribute("bla", "/double")
                    assert_raises(ArgumentError) { node.attribute("bla", "/double") }
                end

                it "should properly set the attribute's attributes" do
                    obj = node.attribute("p", '/double').doc("obj")
                    assert_kind_of(ModelKit::Component::Attribute, obj)
                    assert_equal("p", obj.name)
                    assert_equal('/double', obj.type.full_name)
                    assert_equal("obj",  obj.doc)
                end

                it "provides access to the new attribute with the _attribute accessor" do
                    attribute = node.attribute("p", '/double')
                    assert_same attribute, node.p_attribute
                end
            end

            describe "#property" do
                it "should not allow for duplicate names" do
                    node.property("bla", "/double")
                    assert_raises(ArgumentError) { node.property("bla", "/double") }
                end

                it "should properly set the property attributes" do
                    property = node.property("p", '/double').doc("property")
                    assert_kind_of(ModelKit::Component::Property, property)
                    assert_equal("p", property.name)
                    assert_equal('/double', property.type.full_name)
                    assert_equal("property",  property.doc)
                end

                it "provides access to the new property with the _property accessor" do
                    property = node.property("p", '/double')
                    assert_same property, node.p_property
                end
            end

            describe "#operation" do
                it "registers the operation" do
                    op = node.operation("op")
                    assert_kind_of Operation, op
                    assert_same op, node.find_operation('op')
                    assert_equal [op], node.each_operation.to_a
                end

                it "provides access to the new operation with the _op accessor" do
                    op = node.operation("op")
                    assert_same op, node.op_operation
                end
            end

            describe "#input_port" do
                it "creates and registers an input port object" do
                    port = node.input_port 'i', '/int'
                    assert_kind_of InputPort, port
                    assert_equal port, node.find_input_port('i')
                end

                it "raises ArgumentError if a port with the same name already exists" do
                    node.input_port 'i', '/int'
                    node.output_port 'o', '/int'
                    assert_raises(ArgumentError) { node.input_port 'i', '/int' }
                    assert_raises(ArgumentError) { node.input_port 'o', '/int' }
                end

                it "provides access to the created port with the _port accessor" do
                    p = node.input_port 'i', '/int'
                    assert_same p, node.i_port
                end
            end

            describe "#output_port" do
                it "creates and registers an output port object" do
                    port = node.output_port 'o', '/int'
                    assert_kind_of OutputPort, port
                    assert_equal port, node.find_output_port('o')
                end

                it "raises ArgumentError if a port with the same name already exists" do
                    node.input_port 'i', '/int'
                    node.output_port 'o', '/int'
                    assert_raises(ArgumentError) { node.output_port 'i', '/int' }
                    assert_raises(ArgumentError) { node.output_port 'o', '/int' }
                end

                it "provides access to the created port with the _port accessor" do
                    p = node.output_port 'o', '/int'
                    assert_same p, node.o_port
                end
            end

            describe "interface object promotion" do
                attr_reader :parent_n, :child_n
                before do
                    @parent_n = node
                    @child_n  = parent_n.new_submodel
                end

                def assert_promotes_interface_object(parent)
                    child = yield
                    refute_same parent, child, "parent and child models returned the same object"
                    assert_same parent_n, parent.node, "the parent object does not point to the parent node anymore"
                    assert_same child_n, child.node, "the child object does not point to the child node"
                    assert_same child, yield, "the child object is not cached on the child node model"
                end

                it "promotes attributes to the submodel" do
                    parent   = parent_n.attribute 'test', '/double'
                    assert_promotes_interface_object(parent) { child_n.find_attribute('test') }
                end

                it "promotes properties to the submodel" do
                    parent   = parent_n.property 'test', '/double'
                    assert_promotes_interface_object(parent) { child_n.find_property('test') }
                end

                it "promotes operations to the submodel" do
                    parent   = parent_n.operation 'test'
                    assert_promotes_interface_object(parent) { child_n.find_operation('test') }
                end

                it "promotes input ports to the submodel" do
                    parent   = parent_n.input_port 'test', '/double'
                    assert_promotes_interface_object(parent) { child_n.find_input_port('test') }
                end

                it "promotes output ports to the submodel" do
                    parent   = parent_n.output_port 'test', '/double'
                    assert_promotes_interface_object(parent) { child_n.find_output_port('test') }
                end

                it "promotes dynamic input ports to the submodel" do
                    parent   = parent_n.dynamic_input_port 'test'
                    assert_promotes_interface_object(parent) { child_n.find_dynamic_input_port('test') }
                end

                it "promotes dynamic output ports to the submodel" do
                    parent   = parent_n.dynamic_output_port 'test'
                    assert_promotes_interface_object(parent) { child_n.find_dynamic_output_port('test') }
                end
            end

            describe "#pretty_print" do
                it "passes" do
                    node.pretty_print(PP.new(''))

                    node.doc "description of the node"
                    node.input_port 'i', '/int'
                    node.output_port 'o', '/int'
                    node.dynamic_input_port('dynin', pattern: /r$/, type: "/int")
                    node.dynamic_output_port('dynout', pattern: /w$/, type: "/int")
                    node.operation("op")
                    node.property("p", '/double')
                    node.attribute("a", '/double')
                    node.pretty_print(PP.new(''))
                end
            end

            describe "#to_dot" do
                it "passes" do
                    node.to_dot

                    node.doc "description of the node"
                    node.input_port 'i', '/int'
                    node.output_port 'o', '/int'
                    node.dynamic_input_port('dynin', pattern: /r$/, type: "/int")
                    node.dynamic_output_port('dynout', pattern: /w$/, type: "/int")
                    node.operation("op")
                    node.property("p", '/double')
                    node.attribute("a", '/double')
                    node.to_dot
                end
            end

            describe "dynamic port support" do
                attr_reader :input_port, :output_port
                before do
                    @input_port  = node.dynamic_input_port('dynin', pattern: /r$/, type: "/int")
                    @output_port = node.dynamic_output_port('dynout', pattern: /w$/, type: "/int")
                end

                it "creates input port of class DynamicOutputPort" do
                    assert_kind_of DynamicInputPort, input_port
                end

                it "creates an accessor to get the port" do
                    assert_same input_port, node.dynin_dynamic_port
                end

                it "creates output port of class DynamicOutputPort" do
                    assert_kind_of DynamicOutputPort, output_port
                end

                it "creates an accessor to get the port" do
                    assert_same output_port, node.dynout_dynamic_port
                end

                describe "#each_dynamic_input_port" do
                    it "should list the available dynamic input ports" do
                        assert_equal [input_port], node.each_dynamic_input_port.to_a
                    end
                end
                describe "#find_dynamic_input_ports" do
                    it "can find matching names in the set of ports returned by #each_dynamic_input_port" do
                        assert_equal [input_port], node.find_matching_dynamic_input_ports(name: "blar")
                        assert_equal [], node.find_matching_dynamic_input_ports(name: "blaw")
                    end
                    it "can find matching name and type in the set of ports returned by #each_dynamic_input_port" do
                        assert_equal [input_port], node.find_matching_dynamic_input_ports(name: "blar", type: "/int")
                        assert_equal [], node.find_matching_dynamic_input_ports(name: "blar", type: "/double")
                    end
                end
                describe "#has_matching_dynamic_port?" do
                    it "returns false if both find_matching methods return an empty set" do
                        flexmock(node).should_receive(:find_matching_dynamic_input_ports).
                            with(name: 'name', type: '/type').and_return([])
                        flexmock(node).should_receive(:find_matching_dynamic_output_ports).
                            with(name: 'name', type: '/type').and_return([])
                        assert !node.has_matching_dynamic_port?(name: 'name', type: '/type')
                    end
                    it "returns true if find_matching_dynamic_input returns a non-empty set" do
                        flexmock(node).should_receive(:find_matching_dynamic_input_ports).
                            with(name: 'name', type: '/type').and_return([true])
                        flexmock(node).should_receive(:find_matching_dynamic_output_ports).
                            with(name: 'name', type: '/type').and_return([])
                        assert node.has_matching_dynamic_port?(name: 'name', type: '/type')
                    end
                    it "returns true if find_matching_dynamic_output returns a non-empty set" do
                        flexmock(node).should_receive(:find_matching_dynamic_input_ports).
                            with(name: 'name', type: '/type').and_return([])
                        flexmock(node).should_receive(:find_matching_dynamic_output_ports).
                            with(name: 'name', type: '/type').and_return([true])
                        assert node.has_matching_dynamic_port?(name: 'name', type: '/type')
                    end
                end
                describe "#has_matching_dynamic_input_port?" do
                    it "returns false if #find_dynamic_input_ports returns an empty set" do
                        flexmock(node).should_receive(:find_matching_dynamic_input_ports).with(name: 'name', type: '/type').and_return([])
                        assert !node.has_matching_dynamic_input_port?(name: 'name', type: '/type')
                    end
                    it "returns true if #find_dynamic_input_ports returns a non-empty set" do
                        flexmock(node).should_receive(:find_matching_dynamic_input_ports).with(name: 'name', type: '/type').and_return([true])
                        assert node.has_matching_dynamic_input_port?(name: 'name', type: '/type')
                    end
                end
                describe "#each_dynamic_output_port" do
                    it "should list the available dynamic input ports" do
                        assert_equal [output_port], node.each_dynamic_output_port.to_a
                    end
                end
                describe "#find_dynamic_output_ports" do
                    it "can find matching names in the set of ports returned by #each_dynamic_output_port" do
                        assert_equal [output_port], node.find_matching_dynamic_output_ports(name: "blaw")
                        assert_equal [], node.find_matching_dynamic_output_ports(name: "blar")
                    end
                    it "can find matching name and type in the set of ports returned by #each_dynamic_output_port" do
                        assert_equal [output_port], node.find_matching_dynamic_output_ports(name: "blaw", type: "/int")
                        assert_equal [], node.find_matching_dynamic_output_ports(name: "blaw", type: "/double")
                    end
                end
                describe "#has_matching_dynamic_output_port?" do
                    it "returns false if #find_dynamic_output_ports returns an empty set" do
                        flexmock(node).should_receive(:find_matching_dynamic_output_ports).with(name: 'name', type: '/type').and_return([])
                        assert !node.has_matching_dynamic_output_port?(name: 'name', type: '/type')
                    end
                    it "returns true if #find_dynamic_output_ports returns a non-empty set" do
                        flexmock(node).should_receive(:find_matching_dynamic_output_ports).with(name: 'name', type: '/type').and_return([true])
                        assert node.has_matching_dynamic_output_port?(name: 'name', type: '/type')
                    end
                end
            end

            describe "find_matching_(input|output)_ports" do
                attr_reader :in_p_int, :in_p_double, :out_p_int, :out_p_double
                before do
                    @in_p_int     = node.input_port('in_int', '/int')
                    @in_p_double  = node.input_port('in_double', '/double')
                    @out_p_int    = node.output_port('out_int', '/int')
                    @out_p_double = node.output_port('out_double', '/double')
                end

                describe "#find_matching_input_ports" do
                    it "returns all input ports if given nil for both name and type" do
                        assert_equal node.each_input_port.to_set, node.find_matching_input_ports.to_set
                    end
                    it "returns an empty array if there are no name matches" do
                        assert_equal [], node.find_matching_input_ports(name: "bla")
                    end
                    it "returns an empty array if there are no type matches" do
                        create_dummy_interface_type "/fake"
                        assert_equal [], node.find_matching_input_ports(type: "/fake")
                    end
                    it "returns an empty array if the ports matching the name do not match the type" do
                        assert_equal [], node.find_matching_input_ports(name: 'in_int', type: "/double")
                    end
                    it "returns the input ports that have the given name" do
                        assert_equal [in_p_int], node.find_matching_input_ports(name: "in_int")
                    end
                    it "returns the input ports that match the given name pattern" do
                        assert_equal [in_p_int], node.find_matching_input_ports(name: /int/)
                    end
                    it "returns the input ports that have the given type" do
                        assert_equal [in_p_int], node.find_matching_input_ports(type: "/int")
                    end
                    it "returns the input port that match both name and type" do
                        assert_equal [in_p_int], node.find_matching_input_ports(name: 'in_int', type: "/int")
                    end
                end

                describe "#find_matching_output_ports" do
                    it "returns all output ports if given nil for both name and type" do
                        assert_equal node.each_output_port.to_set, node.find_matching_output_ports.to_set
                    end
                    it "returns an empty array if there are no name matches" do
                        assert_equal [], node.find_matching_output_ports(name: "bla")
                    end
                    it "returns an empty array if there are no type matches" do
                        create_dummy_interface_type "/fake"
                        assert_equal [], node.find_matching_output_ports(type: "/fake")
                    end
                    it "returns an empty array if the ports matching the name do not match the type" do
                        assert_equal [], node.find_matching_output_ports(name: 'out_int', type: "/double")
                    end
                    it "returns the output ports that have the given name" do
                        assert_equal [out_p_int], node.find_matching_output_ports(name: "out_int")
                    end
                    it "returns the output ports that match the given name pattern" do
                        assert_equal [out_p_int], node.find_matching_output_ports(name: /int/)
                    end
                    it "returns the output ports that have the given type" do
                        assert_equal [out_p_int], node.find_matching_output_ports(type: "/int")
                    end
                    it "returns the output port that match both name and type" do
                        assert_equal [out_p_int], node.find_matching_output_ports(name: 'out_int', type: "/int")
                    end
                end
            end

            describe "#to_h" do
                attr_reader :node
                before do
                    @node = ModelKit::Component::Node.new_submodel(project: dummy_project, name: "test::Task")
                end
                it "marshals the model in hash form" do
                    port      = node.input_port('in_p', '/int')
                    property  = node.property('p', '/double')
                    attribute = node.attribute('a', '/double')
                    operation = node.operation('op')
                    h = node.to_h
                    assert_equal node.name, h[:name]
                    assert_equal node.superclass.name, h[:superclass]
                    assert_equal [port.to_h], h[:ports]
                    assert_equal [property.to_h], h[:properties]
                    assert_equal [attribute.to_h], h[:attributes]
                    assert_equal [operation.to_h], h[:operations]
                end
            end

            describe "#merge_ports_from" do
                attr_reader :merged_node
                before do
                    @merged_node = ModelKit::Component::Node.new_submodel(project: dummy_project)
                end

                describe "the handling of static ports" do
                    it "adds the input and output ports of the merged node model" do
                        merged_node.input_port  'in_p', '/double'
                        merged_node.output_port 'out_p', '/int'
                        node.merge_ports_from(merged_node)
                        assert(in_p = node.find_port('in_p'))
                        assert_equal double_t, in_p.type
                        assert(out_p = node.find_port('out_p'))
                        assert_equal int_t, out_p.type
                    end

                    it "rebinds the ports to the new model" do
                        merged_node.input_port  'in_p', '/double'
                        merged_node.output_port 'out_p', '/int'
                        node.merge_ports_from(merged_node)
                        assert_same node, node.find_port('in_p').node
                        assert_same node, node.find_port('out_p').node
                    end

                    it "ignores existing ports" do
                        merged_node.input_port  'in_p', '/double'
                        existing_p = node.input_port  'in_p', '/double'
                        node.merge_ports_from(merged_node)
                        assert_same existing_p, node.find_port('in_p')
                    end

                    it "raises ArgumentError if the receiver has ports with the same name but different directions" do
                        merged_node.input_port  'in_p', '/double'
                        node.output_port  'in_p', '/double'
                        assert_raises(ArgumentError) do
                            node.merge_ports_from(merged_node)
                        end
                    end

                    it "raises ArgumentError if the receiver has ports with the same name but different types" do
                        merged_node.input_port  'in_p', '/double'
                        node.input_port  'in_p', '/int'
                        assert_raises(ArgumentError) do
                            node.merge_ports_from(merged_node)
                        end
                    end
                end

                describe "the handling of dynamic ports" do
                    it "adds the dynamic input and output ports of the merged node model" do
                        merged_node.dynamic_input_port  'in_p', pattern: /^in/, type: '/double'
                        merged_node.dynamic_output_port 'out_p', pattern: /^out/, type: '/int'
                        node.merge_ports_from(merged_node)
                        assert(p = node.find_matching_dynamic_input_ports(name: "in").first)
                        assert_equal /^in/, p.pattern
                        assert_equal double_t, p.type
                        assert(p = node.find_matching_dynamic_output_ports(name: "out").first)
                        assert_equal /^out/, p.pattern
                        assert_equal int_t, p.type
                    end

                    it "rebinds the ports to the new model" do
                        merged_node.input_port  'in_p', '/double'
                        merged_node.output_port 'out_p', '/int'
                        node.merge_ports_from(merged_node)
                        assert_same node, node.find_port('in_p').node
                        assert_same node, node.find_port('out_p').node
                    end

                    it "ignores existing ports" do
                        merged_node.dynamic_input_port  'in_p', pattern: /^in/, type: '/double'
                        existing_p = node.dynamic_input_port  'in_p', pattern: /^in/, type: '/double'
                        node.merge_ports_from(merged_node)
                        assert_same existing_p, node.find_dynamic_port('in_p')
                    end

                    it "raises ArgumentError if the receiver has ports with the same name but different directions" do
                        merged_node.dynamic_output_port  'in_p', pattern: /^in/, type: '/double'
                        node.dynamic_input_port  'in_p', pattern: /^in/, type: '/double'
                        assert_raises(ArgumentError) do
                            node.merge_ports_from(merged_node)
                        end
                    end

                    it "raises ArgumentError if the receiver has ports with the same name but different patterns" do
                        merged_node.dynamic_input_port  'in_p', pattern: /^out/, type: '/double'
                        node.dynamic_input_port  'in_p', pattern: /^in/, type: '/double'
                        assert_raises(ArgumentError) do
                            node.merge_ports_from(merged_node)
                        end
                    end

                    it "raises ArgumentError if the receiver has ports with the same name but different types" do
                        merged_node.dynamic_input_port  'in_p', pattern: /^in/, type: '/int'
                        node.dynamic_input_port  'in_p', pattern: /^in/, type: '/double'
                        assert_raises(ArgumentError) do
                            node.merge_ports_from(merged_node)
                        end
                    end
                end
            end
        end
    end
end

