require 'test_helper'

module ModelKit::Component
    describe Port do
        attr_reader :port
        before do
            create_dummy_interface_type '/double'
            @port = Port.new(dummy_node, 'test', '/double')
            flexmock(port).should_receive(:output_port?).and_return(false).by_default
        end

        it "sets its node" do
            assert_same dummy_node, port.node
        end
        it "sets its name" do
            assert_equal 'test', port.name
        end
        it "resolves a type name on the project" do
            assert_same dummy_loader.registry.get('/double'), port.type
        end

        it "raises NotImplementedError when #output_port is called" do
            port = Port.new(dummy_node, 'test', '/double')
            assert_raises(NotImplementedError) { port.output_port? }
        end

        describe "#to_h" do
            it "marshals the port name" do
                assert_equal 'test', port.to_h[:name]
            end
            it "marshals the port direction" do
                p = Port.new(dummy_node, 'test', '/double')
                flexmock(p).should_receive(:output_port?).and_return(true)
                assert_equal 'output', p.to_h[:direction]

                p = Port.new(dummy_node, 'test', '/double')
                flexmock(p).should_receive(:output_port?).and_return(false)
                assert_equal 'input', p.to_h[:direction]
            end
            it "marshals the port type" do
                assert_equal port.type.to_h, port.to_h[:type]
            end
            it "marshals empty port documentation as an empty string" do
                assert !port.doc
                assert_equal "", port.to_h[:doc]
            end
            it "marshals the port documentation" do
                port.doc('port with documentation')
                assert_equal "port with documentation", port.to_h[:doc]
            end
        end

        describe "#pretty_print" do
            def pretty_print(object)
                pp = PP.new(buffer = "")
                object.pretty_print(pp)
                buffer
            end

            it "does not raise" do
                pretty_print(port)
            end
            it "mentions the port direction" do
                p = Port.new(dummy_node, 'test', '/double')
                flexmock(p).should_receive(:output_port?).and_return(true)
                assert(/out/ === pretty_print(p))

                p = Port.new(dummy_node, 'test', '/double')
                flexmock(p).should_receive(:output_port?).and_return(false)
                assert(/in/ === pretty_print(p))
            end
        end

        describe "static or dynamic connection" do
            it "is dynamic by default" do
                assert !port.static_connections?
            end
            it "becomes static if #static is called" do
                port.static_connections
                assert port.static_connections?
            end
            it "becomes dynamic again if #dynamic is called" do
                port.static_connections
                port.dynamic_connections
                assert !port.static_connections?
            end
        end
    end
end

