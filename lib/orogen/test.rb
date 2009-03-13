require 'test/unit'
require 'fileutils'
require 'orogen'

module Orocos
    module Generation
	module Test
	    include Orocos
	    include Orocos::Generation

	    TEST_DIR      = File.expand_path('../../test', File.dirname(__FILE__))
            TEST_DATA_DIR = File.join( TEST_DIR, 'data' )
            WC_ROOT  = File.join(TEST_DIR, 'wc')

	    attr_reader :working_directory

            def prefix_directory
                File.join(WC_ROOT, "prefix", *subdir)
            end

            attr_reader :subdir

	    def setup
		super if defined? super
	    end

	    def teardown
                clear_wc
		super if defined? super
	    end

	    def create_wc(*subdir)
                required_wc = File.join(TEST_DIR, 'wc', *subdir)
		if working_directory != required_wc
		    @working_directory = required_wc
		    FileUtils.mkdir_p working_directory
                    @subdir = subdir
		end
	    end

            def clear_wc
		unless ENV['TEST_KEEP_WC']
		    if File.directory?(WC_ROOT)
			FileUtils.rm_rf WC_ROOT
                        @working_directory = nil
		    end
		end
            end

	    def copy_in_wc(file, destination = nil)
		if destination
		    destination = File.expand_path(destination, working_directory)
		    FileUtils.mkdir_p destination
		end

		FileUtils.cp File.expand_path(file, TEST_DIR), (destination || working_directory)
	    end

	    def in_wc(&block)
		Dir.chdir(working_directory, &block)
	    end
            def in_prefix(&block)
                old_pkgconfig = ENV['PKG_CONFIG_PATH']
                in_wc do
                    Dir.chdir("build") do
                        if !system("make", "install")
                            raise "failed to install"
                        end
                    end

                    ENV['PKG_CONFIG_PATH'] += ":" + File.join(prefix_directory, 'lib', 'pkgconfig')
                    Dir.chdir(prefix_directory, &block)
                end
            ensure
                ENV['PKG_CONFIG_PATH'] = old_pkgconfig
            end

	    def compile_wc(component)
		in_wc do
                    unless component.deffile
                        component.instance_variable_set(:@deffile, File.join(working_directory, "#{component.name}.orogen"))
                    end
		    component.generate

		    yield if block_given?
		    FileUtils.mkdir('build') unless File.directory?('build')
		    Dir.chdir('build') do
			if !system("cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=#{prefix_directory} ..")
			    raise "failed to configure"
			elsif !system("make")
			    raise "failed to build"
			end
		    end
		end
	    end

            def build_test_component(dirname, with_corba, test_bin = nil)
                if !ENV['TEST_SKIP_REBUILD']
                    source = File.join(TEST_DATA_DIR, dirname)
                    create_wc(dirname)

                    # Copy +dirname+ in place of wc
                    FileUtils.rm_rf working_directory
                    FileUtils.cp_r source, working_directory

                    in_wc do
                        spec = Dir.glob("*.orogen").to_a.first
                        component = Component.load(spec)
                        if with_corba
                            component.enable_corba
                        else
                            component.disable_corba
                        end

                        compile_wc(component) do
                            FileUtils.cp 'templates/CMakeLists.txt', 'CMakeLists.txt'
                            File.open('CMakeLists.txt', 'a') do |io|
                                yield(io) if block_given?
                            end
                        end
                    end
                end

                if test_bin
                    in_prefix do
                        assert(system(test_bin))
                    end
                end
            end


            def compile_and_test(component, test_bin)
                compile_wc(component) do
                    FileUtils.cp 'templates/CMakeLists.txt', 'CMakeLists.txt'
                    File.open('CMakeLists.txt', 'a') do |io|
                        yield(io) if block_given?
                    end
                end

                in_prefix do
                    output = nil
                    assert(system(test_bin))
                end
            end
	end
    end
end

