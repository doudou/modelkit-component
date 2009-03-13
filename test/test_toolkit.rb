require 'orogen/test'

class TC_GenerationToolkit < Test::Unit::TestCase
    include Orocos::Generation::Test

    def test_orocos_type_equivalence
	registry = Typelib::Registry.new

	assert_equal(registry.get('int'), registry.orocos_equivalent(registry.get('int32_t')))
	assert_equal(registry.get('unsigned int'), registry.orocos_equivalent(registry.get('uint32_t')))
	assert_equal(registry.get('int'), registry.orocos_equivalent(registry.get('int16_t')))
	assert_equal(registry.get('unsigned int'), registry.orocos_equivalent(registry.get('uint16_t')))
	assert_equal(registry.get('int'), registry.orocos_equivalent(registry.get('short')))
	assert_equal(registry.get('unsigned int'), registry.orocos_equivalent(registry.get('unsigned short')))

	assert_raises(TypeError) { registry.orocos_equivalent(registry.get('int64_t')) }
    end

    def test_toolkit_load
	component = Component.new
        component.name 'test_toolkit_load'

        assert_raises(RuntimeError) do
            component.toolkit do
                load File.join(TEST_DATA_DIR, 'exists')
            end
        end

        assert_raises(RuntimeError) do
            component.toolkit do
                load 'does_not_exist.h'
            end
        end
    end

    def check_output_file(basedir, name)
        output   = File.read(File.join(prefix_directory, name))
        expected = File.read(File.join(TEST_DATA_DIR, basedir, name))
        assert_equal(expected, output)
    end

    def test_opaque(with_corba = true)
        build_test_component('modules/toolkit_opaque', with_corba, "bin/test") do |cmake|
            cmake << "\nADD_DEFINITIONS(-DWITH_CORBA)" if with_corba
            cmake << "\nADD_EXECUTABLE(test test.cpp)"
            cmake << "\nTARGET_LINK_LIBRARIES(test opaque-toolkit-${OROCOS_TARGET})"
            cmake << "\nTARGET_LINK_LIBRARIES(test ${OROCOS_COMPONENT_LIBRARIES})"
            cmake << "\nINSTALL(TARGETS test RUNTIME DESTINATION bin)"
            cmake << "\n"
	end

        check_output_file('modules/toolkit_opaque', 'opaque.xml')
        check_output_file('modules/toolkit_opaque', 'opaque.cpf')
        check_output_file('modules/toolkit_opaque', 'composed_opaque.xml')
        check_output_file('modules/toolkit_opaque', 'composed_opaque.cpf')
    end
    def test_opaque_without_corba; test_opaque(false) end

    def test_opaque_validation
        # First, check that the actual opaque module generates properly
        create_wc("modules/toolkit_opaque_validation_ok")
        FileUtils.rm_rf working_directory
        FileUtils.cp_r File.join(TEST_DATA_DIR, "modules/toolkit_opaque"), working_directory

        component = Component.new
        in_wc do
            component.load 'opaque.orogen'
            assert_nothing_raised { component.generate }
        end

        # Second, check that it fails if an invalid file is loaded
        create_wc("modules/toolkit_opaque_validation_fail")
        FileUtils.rm_rf working_directory
        FileUtils.cp_r File.join(TEST_DATA_DIR, "modules/toolkit_opaque"), working_directory

        component = Component.new
        in_wc do
            component.load 'opaque.orogen'
            component.toolkit.load File.join(TEST_DATA_DIR, 'opaque_invalid.h')
            assert_raises(NotImplementedError) { component.generate }
        end
    end

    def test_simple(with_corba = true)
        build_test_component('modules/toolkit_simple', with_corba, "bin/test") do |cmake|
             cmake << "\nADD_DEFINITIONS(-DWITH_CORBA)" if with_corba
             cmake << "\nADD_EXECUTABLE(test test.cpp)"
             cmake << "\nTARGET_LINK_LIBRARIES(test simple-toolkit-${OROCOS_TARGET})"
             cmake << "\nTARGET_LINK_LIBRARIES(test ${OROCOS_COMPONENT_LIBRARIES})"
             cmake << "\nINSTALL(TARGETS test RUNTIME DESTINATION bin)"
             cmake << "\n"
        end

        check_output_file('modules/toolkit_simple', 'simple.cpf')
        check_output_file('modules/toolkit_simple', 'simple.xml')
    end
    def test_simple_without_corba; test_simple(false) end
end

