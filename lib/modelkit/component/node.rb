module ModelKit
    module Component
        # Model of a node, i.e. an entity that has inputs, outputs and a
        # configuration interface, and that encapsulates some data processing or
        # data generation
        #
        # Nodes are associated with a Trigger and grouped into Containers
	class Node
            # Note: Node is the only model object in modelkit/component that
            # follows MetaRuby's convention as it is the only one that can be
            # sub-modelled. The other objects are all attributes
            extend Models::Node
	end
    end
end

