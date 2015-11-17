require 'test_helper'

module ModelKit::Component
    describe ConfigurationObject do
        before do
            create_dummy_interface_type '/double'
        end

        subject do
            dummy_node.property('p', '/double')
        end

        it "is not dynamic by default" do
            assert !subject.dynamic?
        end

        describe "#dynamic" do
            it "sets the dynamic flag" do
                subject.dynamic
                assert subject.dynamic?
            end
        end

        describe "#pretty_print" do
            it "does not raise" do
                subject.default_value 10
                subject.doc "with documentation"
                pp = PP.new("")
                flexmock(dummy_node).should_receive(:pretty_print)
                subject.pretty_print(pp)
            end
        end

        describe "#to_h" do
            it "marshals the name" do
                assert_equal 'p', subject.to_h[:name]
            end
            it "marshals the type" do
                assert_equal subject.type.to_h, subject.to_h[:type]
            end
            it "marshals whether the object is dynamic or not" do
                assert_equal false, subject.to_h[:dynamic]
                flexmock(subject).should_receive(:dynamic?).and_return(true)
                assert_equal true, subject.to_h[:dynamic]
            end
            it "marshals empty documentation as an empty string" do
                p = dummy_node.property 'with_no_documentation', '/double'
                assert_equal "", p.to_h[:doc]
            end
            it "marshals the documentation" do
                subject = dummy_node.property('with_documentation', '/double').
                    doc('with documentation')
                assert_equal "with documentation", subject.to_h[:doc]
            end
            it "does not add a default field if the configuration object has no default value" do
                assert !subject.to_h.has_key?(:default)
            end
            it "assigns a simple default value if there is one" do
                flexmock(subject).should_receive(:default_value).and_return(v = flexmock)
                assert_equal v, subject.to_h[:default]
            end
            it "marshals the default value if there is one" do
                flexmock(subject).should_receive(:default_value).and_return(v = flexmock)
                v.should_receive(:to_simple_value).and_return(marshalled = flexmock)
                assert_equal marshalled, subject.to_h[:default]
            end
        end
    end
end

