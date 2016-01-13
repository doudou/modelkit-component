require 'test_helper'

module ModelKit::Component
    describe InputPort do
        attr_reader :port
        before do
            create_dummy_interface_type '/double'
            @port = InputPort.new(dummy_node, 'test', '/double')
        end

        it "is not an output port" do
            assert !port.output_port?
        end

        it "can modify the needs_reliable_connection property" do
            assert !port.needs_reliable_connection?
            port.needs_reliable_connection
            assert port.needs_reliable_connection?
        end

        it "can modify the clean_on_node_start property" do
            assert port.clean_on_node_start?
            port.do_not_clean_on_node_start
            assert !port.clean_on_node_start?
        end

        it "can modify the multiplexing property" do
            assert !port.multiplexes?
            port.multiplexes
            assert port.multiplexes?
        end
    end
end

