require 'test_helper'

module ModelKit::Component
    describe DynamicPort do
        attr_reader :port_m, :double_t
        before do
            @port_m = Class.new(Port) do
                include DynamicPort
            end

            @double_t = create_dummy_interface_type '/double'
        end

        describe "#instanciate" do
            it "raises ArgumentError if the given name does not match the expected pattern" do
                port = port_m.new(dummy_node, 'test', pattern: /^t/, type: '/double')
                assert_raises(ArgumentError) do
                    port.instanciate('foo')
                end
            end
            it "passes if no pattern was defined" do
                port = port_m.new(dummy_node, 'test', pattern: nil, type: '/double')
                instance = port.instanciate('foo')
                assert_equal 'foo', instance.name
                assert_equal double_t, instance.type
            end

            it "raises ArgumentError if no type is specified on the port and none is given to the method" do
                port = port_m.new(dummy_node, 'test', pattern: nil)
                assert_raises(ArgumentError) do
                    port.instanciate('foo')
                end
            end

            it "raises ArgumentError if the type specified on the port does not match the one given to the method" do
                int_t = create_dummy_interface_type '/int'
                port = port_m.new(dummy_node, 'test', pattern: nil, type: double_t)
                assert_raises(ArgumentError) do
                    port.instanciate('foo', int_t)
                end
            end

            it "uses the port specified on the port if there is one" do
                int_t = create_dummy_interface_type '/int'
                port = port_m.new(dummy_node, 'test', pattern: nil, type: double_t)
                instance = port.instanciate('foo')
                assert_equal 'foo', instance.name
                assert_equal double_t, instance.type
            end
        end

        describe "#pretty_print" do
            it "passes" do
                port = port_m.new(dummy_node, 'test', pattern: /^t/, type: '/double')
                port.pretty_print(PP.new(''))
            end
        end
    end
end
