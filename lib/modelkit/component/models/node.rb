module ModelKit
    module Component
        module Models
            # Model of a node, i.e. an entity that has inputs, outputs and a
            # configuration interface
            #
            # Nodes are associated with Trigger and grouped into Containers
            module Node
                include MetaRuby::ModelAsClass
                extend MetaRuby::Attributes

                # The project this task is part of
                #
                # @return [Project]
                attr_reader :project

                # The loader that has been used to load this task context
                #
                # @return [Loaders::Base]
                def loader; project.loader end

                def promote_attribute(name, obj)
                    attributes[name] = obj.dup.rebind(self)
                end
                inherited_attribute 'attribute', 'attributes', map: true, yield_key: false do
                    Hash.new
                end

                def promote_property(name, obj)
                    properties[name] = obj.dup.rebind(self)
                end
                inherited_attribute 'property', 'properties', map: true, yield_key: false do
                    Hash.new
                end

                def promote_input_port(name, obj)
                    input_ports[name] = obj.dup.rebind(self)
                end
                inherited_attribute 'input_port', 'input_ports', map: true, yield_key: false do
                    Hash.new
                end

                def promote_output_port(name, obj)
                    output_ports[name] = obj.dup.rebind(self)
                end
                inherited_attribute 'output_port', 'output_ports', map: true, yield_key: false do
                    Hash.new
                end

                def promote_operation(name, obj)
                    operations[name] = obj.dup.rebind(self)
                end
                inherited_attribute 'operation', 'operations', map: true, yield_key: false do
                    Hash.new
                end

                def promote_dynamic_input_port(name, obj)
                    dynamic_input_ports[name] = obj.dup.rebind(self)
                end
                inherited_attribute 'dynamic_input_port', 'dynamic_input_ports', map: true, yield_key: false do
                    Hash.new
                end

                def promote_dynamic_output_port(name, obj)
                    dynamic_output_ports[name] = obj.dup.rebind(self)
                end
                inherited_attribute 'dynamic_output_port', 'dynamic_output_ports', map: true, yield_key: false do
                    Hash.new
                end

                # Enumerate both input and output dynamic ports
                #
                # @overload each_dynamic_port
                #   @return [#each]
                #
                # @overload each_dynamic_port
                #   @yieldparam [DynamicInputPort,DynamicOutputPort]
                #
                # @see each_dynamic_input_port each_dynamic_output_port
                def each_dynamic_port(&block)
                    return enum_for(__method__) if !block_given?
                    each_dynamic_input_port(&block)
                    each_dynamic_output_port(&block)
                end

                # Enumerates both the input and output ports
                #
                # @overload each_port
                #   @return [#each]
                #
                # @overload each_port
                #   @yieldparam [InputPort,OutputPort]
                #
                # @see each_dynamic_input_port each_dynamic_output_port
                def each_port(&block)
                    return enum_for(__method__) if !block_given?
                    each_input_port(&block)
                    each_output_port(&block)
                end

                # Gets or sets the documentation string for this task context
                #
                # @overload doc
                #   @return [String]
                #
                # @overload doc(string)
                #   @param [String] string the new documentation string
                dsl_attribute :doc

                def to_s; "#<ModelKit::Component::Node: #{name}>" end
                def inspect; to_s end

                # The task name
                attr_reader :name

                # Call to declare that this task model is not meant to run in
                # practice, i.e. only serves as a base model for other models
                def abstract; @abstract = true; end

                # True if this task model is only meant to declare an interface, and
                # should not be deployed
                def abstract?; @abstract end

                # @api private
                #
                # Hook called by MetaRuby when a new submodel is created with
                # #new_submodel
                def setup_submodel(submodel, project: nil)
                    super(submodel)
                    submodel.instance_variable_set :@project, project
                end

                def pretty_print_interface(pp, name, set)
                    if set.empty?
                        pp.text "No #{name.downcase}"
                    else
                        pp.text name
                        pp.nest(2) do
                            set = set.to_a.sort_by { |p| p.name.to_s }
                            set.each do |element|
                                pp.breakable
                                element.pretty_print(pp)
                            end
                        end
                    end
                    pp.breakable
                end

                def pretty_print(pp)
                    pp.text "------- #{name} ------"
                    pp.breakable
                    if doc
                        first_line = true
                        doc.split("\n").each do |line|
                            pp.breakable if !first_line
                            first_line = false
                            pp.text "# #{line}"
                        end
                        pp.breakable
                        pp.text "# "
                    else
                        pp.text "no documentation defined for this task context model"
                    end
                    pp.breakable
                    pp.text "subclass of #{superclass.name} (the superclass elements are displayed below)"
                    pp.breakable

                    pretty_print_interface(pp, "Ports", each_port.to_a)
                    pretty_print_interface(pp, "Dynamic Ports", each_dynamic_port.to_a)
                    pretty_print_interface(pp, "Properties", each_property.to_a)
                    pretty_print_interface(pp, "Attributes", each_attribute.to_a)
                    pretty_print_interface(pp, "Operations", each_operation.to_a)
                end

                # Raises ArgumentError if an object named +name+ is already present
                # in the set attribute +set_name+. 
                #
                # This is an internal helper method
                def check_uniqueness(name) # :nodoc:
                    obj = find_input_port(name) ||
                        find_output_port(name) ||
                        find_operation(name) ||
                        find_property(name) ||
                        find_attribute(name)

                    if obj
                        raise ArgumentError, "#{name} is already used in the interface of #{self.name}, as a #{obj.class}"
                    end
                end

                # Create a new attribute with the given name, type and default value
                # for this task. This returns an Attribute instance representing
                # the new attribute, whose methods can be used to configure it
                # further. +type+ is the type name for that attribute.
                #
                # @example
                #   # The device name to connect to
                #   attribute('device_name', '/std/string/, '')
                def attribute(name, type, default_value: default_value)
                    check_uniqueness(name)
                    attributes[name] = attr = configuration_object(Attribute, name, type, default_value: default_value)
                    singleton_class.class_eval do
                        define_method "#{name}_attribute" do
                            find_attribute(name)
                        end
                    end
                    attr
                end

                # Create a new property with the given name, type and default value
                # for this task
                #
                # @example
                #   # The device name to connect to
                #   property('device_name', '/std/string/, '')
                def property(name, type, default_value: nil)
                    check_uniqueness(name)
                    properties[name] = prop = configuration_object(Property, name, type, default_value: default_value)
                    singleton_class.class_eval do
                        define_method "#{name}_property" do
                            find_property(name)
                        end
                    end
                    prop
                end

                # @api private
                #
                # Helper method to build configuration objects (i.e. properties
                # and attributes)
                def configuration_object(klass, name, type, default_value: default_value)
                    check_uniqueness(name)
                    type = loader.resolve_interface_type(type)
                    klass.new(self, name, type, default_value: default_value)
                end

                # Create a new operation with the given name. Use the returned
                # Operation object to configure it further
                def operation(name)
                    name = name.to_str
                    check_uniqueness(name)

                    operations[name] = op = Operation.new(self, name)
                    singleton_class.class_eval do
                        define_method "#{name}_operation" do
                            find_operation(name)
                        end
                    end
                    op
                end

                # Add a new write port with the given name and type, and returns the
                # corresponding OutputPort object.
                #
                # See also #input_port
                def output_port(name, type, class_object: OutputPort)
                    name = name.to_str
                    check_uniqueness(name)

                    output_ports[name] = port = class_object.new(self, name, type)
                    singleton_class.class_eval do
                        define_method "#{name}_port" do
                            find_output_port(name)
                        end
                    end
                    port
                end

                # Add a new input port with the given name and type, and returns the
                # corresponding InputPort object.
                #
                # See also #output_port
                def input_port(name, type, class_object: InputPort)
                    name = name.to_str
                    check_uniqueness(name)

                    input_ports[name] = port = class_object.new(self, name, type)
                    singleton_class.class_eval do
                        define_method "#{name}_port" do
                            find_input_port(name)
                        end
                    end
                    port
                end

                # Finds the set of ports matching either a name or type (or both)
                #
                # @return [Array<InputPort>]
                def find_matching_input_ports(name: nil, type: nil)
                    if name && name.respond_to?(:to_str)
                        if p = find_input_port(name.to_str)
                            return filter_matching_ports([p], name: nil, type: type)
                        else return Array.new
                        end
                    end
                    filter_matching_ports(each_input_port, name: name, type: type)
                end

                # Finds a port matching either a name or type (or both)
                #
                # @return [Array<OutputPort>]
                def find_matching_output_ports(name: nil, type: nil)
                    if name && name.respond_to?(:to_str)
                        if p = find_output_port(name.to_str)
                            return filter_matching_ports([p], name: nil, type: type)
                        else return Array.new
                        end
                    end
                    filter_matching_ports(each_output_port, name: name, type: type)
                end

                # @api private
                #
                # Helper for {#find_matching_input_ports} and
                # {#find_matching_output_ports}
                def filter_matching_ports(ports, name: nil, type: nil)
                    if name
                        ports = ports.find_all { |p| name === p.name }
                    end
                    if type
                        type = loader.resolve_interface_type(type)
                        ports = ports.find_all { |p| p.type == type }
                    end
                    ports
                end

                # Finds a port by its name, and optionally validate its type
                def find_port(name)
                    find_output_port(name.to_str) || find_input_port(name.to_str)
                end

                # Returns true if this task interface has a port named 'name'. If a
                # type is given, the corresponding port will be matched against that
                # type as well
                def has_port?(name)
                    !!find_port(name)
                end

                # Declares that a port whose name matches name_regex can be declared
                # at runtime, with the type. This is not used by orogen himself, but
                # can be used by potential users of the orogen specification.
                def dynamic_input_port(name, pattern: nil, type: VoidType)
                    port = DynamicInputPort.new(self, name, pattern: pattern, type: type)
                    singleton_class.class_eval do
                        define_method "#{name}_dynamic_port" do
                            find_dynamic_input_port name
                        end
                    end
                    dynamic_input_ports[name] = port
                end

                # Declares that a port whose name matches name_regex can be declared
                # at runtime, with the type. This is not used by orogen himself, but
                # can be used by potential users of the orogen specification.
                def dynamic_output_port(name, pattern: nil, type: VoidType)
                    port = DynamicOutputPort.new(self, name, pattern: pattern, type: type)
                    singleton_class.class_eval do
                        define_method "#{name}_dynamic_port" do
                            find_dynamic_output_port name
                        end
                    end
                    dynamic_output_ports[name] = port
                end

                # Verifies if there is a dynamic port with that name
                def has_dynamic_port?(name)
                    !!find_dynamic_port(name)
                end

                # Verifies if there is a dynamic port with that name
                def find_dynamic_port(name)
                    name = name.to_str
                    find_dynamic_input_port(name) || find_dynamic_output_port(name)
                end

                # @api private
                #
                # Helper method for {#find_matching_dynamic_input_ports} and
                # {#find_matching_dynamic_output_ports}
                def filter_matching_dynamic_ports(ports, name: nil, type: nil)
                    if name
                        ports = ports.find_all { |p| !p.pattern || p.pattern === name }
                    end
                    if type
                        type = loader.resolve_interface_type(type)
                        ports = ports.find_all { |p| !p.type || p.type == type }
                    end
                    ports
                end

                # Returns the set of dynamic input port definitions that match the
                # given name and type pair. If +type+ is nil, the type is ignored in
                # the matching.
                def find_matching_dynamic_input_ports(name: nil, type: nil)
                    filter_matching_dynamic_ports(each_dynamic_input_port, name: name, type: type)
                end

                # Returns true if there is an input port definition that match the
                # given name and type pair. If +type+ is nil, the type is ignored in
                # the matching.
                def has_matching_dynamic_input_port?(name: nil, type: nil)
                    !find_matching_dynamic_input_ports(name: name, type: type).empty?
                end

                # Returns the set of dynamic output port definitions that match the
                # given name and type pair. If +type+ is nil, the type is ignored in
                # the matching.
                def find_matching_dynamic_output_ports(name: nil, type: nil)
                    filter_matching_dynamic_ports(each_dynamic_output_port, name: name, type: type)
                end

                # Returns true if an output port of the given name and type could be
                # created at runtime.
                def has_matching_dynamic_output_port?(name: nil, type: nil)
                    !find_matching_dynamic_output_ports(name: name, type: type).empty?
                end

                # Returns true if there is a dynamic port definition that matches
                # a given port name and/or type
                def has_matching_dynamic_port?(name: nil, type: nil)
                    has_matching_dynamic_input_port?(name: name, type: type) ||
                        has_matching_dynamic_output_port?(name: name, type: type)
                end

                # Generate a graphviz fragment to represent this task
                def to_dot
                    html_escape = lambda { |s| s.gsub(/</, "&lt;").gsub(/>/, "&gt;") }
                    html_table  = lambda do |title, lines|
                        label  = "<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\">\n"
                        label << "  <TR><TD>#{title}</TD></TR>\n"
                        label << "  <TR><TD>\n"
                        label << lines.join("<BR/>\n")
                        label << "  </TD></TR>\n"
                        label << "</TABLE>"
                    end
                        
                    result = ""
                    result << "  node [shape=none,margin=0,height=.1];"

                    label = ""
                    label << "<TABLE BORDER=\"0\" CELLBORDER=\"0\" CELLSPACING=\"0\">\n"
                    label << "  <TR><TD>#{name}</TD></TR>"

                    properties = each_property.
                        map { |p| "#{p.name} [#{html_escape[p.type.name]}]" }
                    if !properties.empty?
                        label << "  <TR><TD>#{html_table["Properties", properties]}</TD></TR>"
                    end


                    input_ports = each_input_port.
                        map { |p| "#{p.name} [#{html_escape[p.type.name]}]" }
                    if !input_ports.empty?
                        label << "  <TR><TD>#{html_table["Input ports", input_ports]}</TD></TR>"
                    end

                    output_ports = each_output_port.
                        map { |p| "#{p.name} [#{html_escape[p.type.name]}]" }
                    if !output_ports.empty?
                        label << "  <TR><TD>#{html_table["Output ports", output_ports]}</TD></TR>"
                    end

                    label << "</TABLE>"
                    result << "  t#{object_id} [label=<#{label}>]"
                    result
                end

                # Converts this model into a representation that can be fed to e.g.
                # a JSON dump, that is a hash with pure ruby key / values.
                #
                # The generated hash has the following keys:
                #
                #     name: the name
                #     superclass: the name of this model's superclass (if there is
                #       one)
                #     states: the list of defined states, as formatted by
                #       {each_state}
                #     ports: the list of ports, as formatted by {Port#to_h}
                #     properties: the list of properties, as formatted by
                #       {ConfigurationObject#to_h}
                #     attributes: the list of attributes, as formatted by
                #       {ConfigurationObject#to_h}
                #     operations: the list of operations, as formatted by
                #       {Operation#to_h}
                #
                # @return [Hash]
                def to_h
                    Hash[
                        name: name,
                        superclass: superclass.name,
                        ports: each_port.map(&:to_h),
                        properties: each_property.map(&:to_h),
                        attributes: each_attribute.map(&:to_h),
                        operations: each_operation.map(&:to_h)
                    ]
                end

                # Add in +self+ the ports of +other_model+ that don't exist.
                #
                # Raises ArgumentError if +other_model+ has ports whose name is used
                # in +self+, but for which the definition is different.
                def merge_ports_from(other_model, name_mappings = Hash.new)
                    other_model.each_port do |p|
                        p = p.dup
                        p.rebind(self, name: name_mappings[p.name] || p.name)

                        if has_port?(p.name)
                            self_port = find_port(p.name)
                            if self_port.class != p.class
                                raise ArgumentError, "cannot merge as #{self_port.name} is a #{self_port.class} in #{self} and a #{p.class} in #{other_model}"
                            elsif self_port.type != p.type
                                raise ArgumentError, "cannot merge as #{self_port.name} is of type #{self_port.type} in #{self} and of type #{p.type} in #{other_model}"
                            end
                        elsif p.kind_of?(OutputPort)
                            output_ports[p.name] = p
                        elsif p.kind_of?(InputPort)
                            input_ports[p.name] = p
                        end
                    end
                    other_model.each_dynamic_port do |p|
                        p = p.dup
                        p.rebind(self, name: name_mappings[p.name] || p.name)

                        if has_dynamic_port?(p.name)
                            self_port = find_dynamic_port(p.name)
                            if self_port.class != p.class
                                raise ArgumentError, "cannot merge as #{self_port.name} is a #{self_port.class} in #{self} and a #{p.class} in #{other_model}"
                            elsif self_port.type != p.type
                                raise ArgumentError, "cannot merge as #{self_port.name} is of type #{self_port.type} in #{self} and of type #{p.type} in #{other_model}"
                            elsif self_port.pattern != p.pattern
                                raise ArgumentError, "cannot merge as #{self_port.name} matches pattern #{self_port.pattern} in #{self} and pattern #{p.pattern} in #{other_model}"
                            end
                        elsif p.kind_of?(OutputPort)
                            dynamic_output_ports[p.name] = p
                        elsif p.kind_of?(InputPort)
                            dynamic_input_ports[p.name] = p
                        end
                    end
                end
            end
        end
    end
end

