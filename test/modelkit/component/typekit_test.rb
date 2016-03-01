require 'test_helper'

module ModelKit::Component
    describe Typekit do
        attr_reader :typekit
        before do
            @typekit = Typekit.new(Loaders::Base.new)
        end

        describe "#self_types" do
            it "lists the types that are defined by the typekit" do
                types = [typekit.create_null('/test0'), typekit.create_null('/test1')]
                assert_equal Set['/test0', '/test1'], typekit.typelist
                assert_equal types.to_set, typekit.self_types.to_set
            end
        end

        describe "#defines_array_of?" do
            before do
                typekit.create_null('/test0')
                typekit.create_array('/test0', 10)
                typekit.create_null('/test1')
            end

            it "returns false if none of the self_types is an array" do
                assert !typekit.defines_array_of?('/test1')
            end
            it "returns true if at least one of the self_types is an array" do
                assert typekit.defines_array_of?('/test0')
            end
        end

        describe "#include?" do
            before do
                typekit.create_null('/test0')
            end

            it "returns true for a type that is defined by the typekit" do
                assert typekit.include?('/test0')
            end
            it "returns false for a type that is not known to the typekit" do
                assert !typekit.include?('/test1')
            end
            it "returns false for a type that is known to the typekit but not defined by it" do
                typekit.registry.create_null('/test1')
                assert !typekit.include?('/test1')
            end
        end

        describe "#interface_type?" do
            before do
                typekit.create_interface_null('/test0')
                typekit.create_null('/test1')
            end

            it "returns true for an interface type that is defined by the typekit" do
                assert typekit.interface_type?('/test0')
            end
            it "returns false for a non-interface type that is defined by the typekit" do
                assert !typekit.interface_type?('/test1')
            end
            it "returns false for a type that is not known to the typekit" do
                assert !typekit.interface_type?('/test2')
            end
            it "returns false for a type that is known to the typekit but not defined by it" do
                typekit.registry.create_null('/test2')
                assert !typekit.interface_type?('/test2')
            end
        end

        describe "#resolve_type" do
            attr_reader :test_t
            before do
                @test_t = typekit.create_null('/test')
            end
            it "resolves a type by name" do
                assert_same test_t, typekit.resolve_type('/test')
            end
            it "returns the typekit's type that matches the given's type name" do
                assert_same test_t, typekit.resolve_type(flexmock(name: '/test'))
            end
        end

        describe "#respond_to_missing" do
            it "returns true for methods that are registry type creation methods" do
                assert typekit.send(:respond_to_missing?, :create_null)
                assert typekit.send(:respond_to_missing?, :create_interface_numeric)
            end
            it "returns false for methods that are not registry type creation methods" do
                assert !typekit.send(:respond_to_missing?, :foobar)
                assert !typekit.send(:respond_to_missing?, :create_does_not_exist)
                assert !typekit.send(:respond_to_missing?, :create_interface_does_not_exist)
            end
        end

        describe "#method_missing" do
            it "raises for methods that are not registry type creation methods" do
                assert_raises(NoMethodError) { typekit.foobar }
                assert_raises(NoMethodError) { typekit.create_does_not_exist }
                assert_raises(NoMethodError) { typekit.create_interface_does_not_exist }
            end
        end

        describe "#inspect" do
            it "passes" do
                typekit.inspect
            end
        end
    end
end

