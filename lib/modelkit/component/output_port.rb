module ModelKit
    module Component
        # Specification for an output port
        class OutputPort < Port
            # Overloaded from {Port#output_port?} to mark that instances of this
            # class are outputs
            def output_port?
                true
            end
        end
    end
end


