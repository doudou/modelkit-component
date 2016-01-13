require 'test_helper'

module ModelKit::Component
    describe Operation do
        attr_reader :operation
        attr_reader :double_t
        before do
            @double_t = create_dummy_interface_type '/double'
            @operation = Operation.new(dummy_node, 'test')
        end

        describe "#doc" do
            it "sets the documentation" do
                doc = "test documentation"
                operation.doc(doc)
                assert_equal doc, operation.doc
            end
        end

        it "controls the in/out callee thread property" do
            assert operation.in_callee_thread?
            operation.runs_outside_callee_thread
            assert !operation.in_callee_thread?
            operation.runs_in_callee_thread
            assert operation.in_callee_thread?
        end

        describe "#argument" do
            it "returns self" do
                assert_same operation, operation.argument('arg', '/double')
            end
            it "defines the argument" do
                operation.argument('arg', '/double', 'a documentation')
                arg = operation.find_argument_by_name('arg')
                assert_equal 'arg', arg.name
                assert_equal double_t, arg.type
                assert_equal 'a documentation', arg.doc
            end
            it "raises DuplicateArgument if the same argument name is used multiple times" do
                operation.argument('arg', '/double', 'a documentation')
                assert_raises(Operation::DuplicateArgument) do
                    operation.argument('arg', '/double', 'a documentation')
                end
            end
        end

        it "pretty-prints itself" do
            # We really just check that there are no errors
            operation.doc "blablabla"
            operation.returns '/double', 'a documentation'
            operation.argument 'test', '/double', 'a documentation'
            operation.pretty_print(PP.new(""))
        end

        it "returns nothing by default" do
            assert !operation.has_return_value?
            assert !operation.return_value.doc
        end

        it "defines a return value" do
            operation.returns '/double', 'a documentation'
            assert operation.has_return_value?
            assert_equal double_t, operation.return_value.type
            assert_equal 'a documentation', operation.return_value.doc
        end

        it "resets the return value and documentation" do
            operation.returns '/double', 'a documentation'
            operation.returns_nothing
            assert !operation.has_return_value?
            assert !operation.return_value.doc
        end


        describe "#to_h" do
            it "marshals the name" do
                assert_equal 'test', operation.to_h[:name]
            end
            it "marshals empty documentation as an empty string" do
                operation.doc ""
                assert_equal "", operation.to_h[:doc]
            end
            it "marshals the documentation" do
                operation.doc "with documentation"
                assert_equal "with documentation", operation.to_h[:doc]
            end
            it "does not add a return field if the operation returns nothing" do
                assert !operation.to_h.has_key?(:returns)
            end
            it "marshals the typelib return type if the operation returns a value" do
                operation.returns("/double")
                assert_equal double_t.to_h,
                    operation.to_h[:returns][:type]
            end
            it "sets an empty return type documentation if none is specified" do
                operation.returns("/double")
                assert_equal "", operation.to_h[:returns][:doc]
            end
            it "sets the return type documentation field to the provided documentation" do
                operation.returns("/double", "return type description")
                assert_equal "return type description", operation.to_h[:returns][:doc]
            end
            it "sets the arguments field to an empty array if there are none" do
                assert_equal [], operation.to_h[:arguments]
            end
            it "marshals its arguments" do
                operation.argument('arg', '/double')
                assert_equal [Hash[name: 'arg', type: double_t.to_h, doc: ""]], operation.to_h[:arguments]
            end
            it "marshals its arguments documentation" do
                operation.argument('arg', '/double', 'arg documentation')
                assert_equal [Hash[name: 'arg', type: double_t.to_h, doc: "arg documentation"]], operation.to_h[:arguments]
            end
        end
    end
end

