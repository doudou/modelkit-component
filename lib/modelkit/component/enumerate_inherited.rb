class Module
    def enumerate_inherited_set(each_name, attribute_name = each_name) # :nodoc:
	class_eval <<-EOD, __FILE__, __LINE__
	def find_#{attribute_name}(name) 
            each_#{each_name} do |n|
                return n if n.name == name
            end
        end
	def all_#{attribute_name}; each_#{each_name}.to_a end
	def self_#{attribute_name}; @#{attribute_name} end
	def each_#{each_name}(&block)
	    if block_given?
		if superclass
		    superclass.each_#{each_name}(&block)
		end
		@#{attribute_name}.each(&block)
	    else
		enum_for(:each_#{each_name})
	    end
	end
	EOD
    end

    def enumerate_inherited_map(each_name, attribute_name = each_name) # :nodoc:
	class_eval <<-EOD, __FILE__, __LINE__
        attr_reader :#{attribute_name}
	def all_#{attribute_name}; each_#{each_name}.to_a end
	def self_#{attribute_name}; @#{attribute_name}.values end
	def has_#{attribute_name}?(name); !!find_#{each_name}(name) end

	def find_#{each_name}(name)
            name = name.to_str
	    if v = @#{attribute_name}[name]
		v
	    elsif superclass
		superclass.find_#{each_name}(name)
	    end
	end
	def each_#{each_name}(&block)
	    if block_given?
		if superclass
		    superclass.each_#{each_name}(&block)
		end
		@#{attribute_name}.each_value(&block)
	    else
		enum_for(:each_#{each_name})
	    end
	end
	EOD
    end
end

