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
    end
end

