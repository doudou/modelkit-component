require 'test_helper'

module ModelKit::Component
    describe OutputPort do
        attr_reader :port
        before do
            create_dummy_interface_type '/double'
            @port = OutputPort.new(dummy_node, 'test', '/double')
        end

        it "is declared as an output port" do
            assert port.output_port?
        end

        describe "#period" do
            it "returns the period" do
                assert_equal 1, port.period
            end
            it "sets the sample size" do
                port.period(10)
                assert_equal 10, port.period
            end
            it "validates that the sample size is an integer" do
                assert_raises(ArgumentError) { port.period('bla') }
            end
        end

        describe "burst" do
            it "sets burst size and period" do
                port.burst(20, period: 5)
            end
            it "validates that the burst size is an integer" do
                assert_raises(ArgumentError) { port.burst('bal', period: 5) }
            end
            it "does not change the parameters if the size does not validate" do
                port.burst(20, period: 5)
                assert_raises(ArgumentError) { port.burst('bal', period: 2) }
                assert_equal 20, port.burst_size
                assert_equal 5, port.burst_period
            end
            it "validates that the burst period is an integer" do
                assert_raises(ArgumentError) { port.burst(20, period: 'bla') }
            end
            it "does not change the parameters if the period does not validate" do
                port.burst(20, period: 5)
                assert_raises(ArgumentError) { port.burst(20, period: 'bla') }
                assert_equal 20, port.burst_size
                assert_equal 5, port.burst_period
            end
        end

        describe "#sample_size" do
            it "returns the sample size" do
                assert_equal 1, port.sample_size
            end
            it "sets the sample size" do
                port.sample_size(10)
                assert_equal 10, port.sample_size
            end
            it "validates that the sample size is an integer" do
                assert_raises(ArgumentError) { port.sample_size('bla') }
            end
        end

        describe "#triggered_on" do
            attr_reader :test_input_port

            before do
                @test_input_port = InputPort.new(dummy_node, 'test_input', '/double')
            end
            it "adds a port object to the port_triggers set" do
                port.triggered_on(test_input_port)
                assert_equal [test_input_port].to_set, port.port_triggers
            end
            it "raises if the given port is an output port" do
                flexmock(test_input_port).should_receive(:output_port?).and_return(true)
                assert_raises(ArgumentError) { port.triggered_on(test_input_port) }
                assert port.port_triggers.empty?
            end
            it "raises if the port is a port of another node" do
                flexmock(test_input_port).should_receive(:node).and_return(flexmock)
                assert_raises(ArgumentError) { port.triggered_on(test_input_port) }
                assert port.port_triggers.empty?
            end
            it "resolves port names on the node" do
                flexmock(dummy_node).should_receive(:find_input_port).with('test_input').and_return(test_input_port)
                port.triggered_on('test_input')
                assert_equal [test_input_port].to_set, port.port_triggers
            end
            it "raises ArgumentError if a port name does not resolve" do
                assert_raises(ArgumentError) { port.triggered_on('test_input') }
                assert port.port_triggers.empty?
            end
            it "raises Incompatibility if the port is already marked as triggering once per update" do
                port.triggered_once_per_update
                assert_raises(Incompatibility) { port.triggered_on('test') }
            end
            it "sets has_port_triggers?" do
                assert !port.has_port_triggers?
                flexmock(dummy_node).should_receive(:find_input_port).with('test_input').and_return(test_input_port)
                port.triggered_on('test_input')
                assert port.has_port_triggers?
            end
        end

        describe 'trigger-on-update' do
            it "is true by default" do
                assert port.triggered_on_update?
            end
            it "is false if a port trigger has been added" do
                flexmock(port).should_receive(:has_port_triggers?).and_return(true)
                assert !port.triggered_on_update?
            end
            it "can be overriden to true by calling triggered_on_update explicitely before the port has been added" do
                port.triggered_on_update
                flexmock(port).should_receive(:has_port_triggers?).and_return(true)
                assert port.triggered_on_update?
            end
            it "can be overriden to true by calling triggered_on_update explicitely after the port has been added" do
                flexmock(port).should_receive(:has_port_triggers?).and_return(true)
                port.triggered_on_update
                assert port.triggered_on_update?
            end
        end

        describe "once-per-update trigger" do
            it "sets the flag and returns self" do
                assert_same port, port.triggered_once_per_update
                assert port.triggered_once_per_update?
            end
            it "raises Incompatibility if the port is triggered by other ports" do
                flexmock(port).should_receive(:has_port_triggers?).and_return(true)
                assert_raises(Incompatibility) { port.triggered_once_per_update }
            end
        end
    end
end

