require 'test_helper'

module ModelKit::Component
    module Loaders
        describe Base do
            attr_reader :loader

            before do
                @loader = Base.new
            end

            describe "#initialize" do
                it "does not call #added_child if the root is self" do
                    flexmock(Base).new_instances.should_receive(:added_child).never
                    Base.new
                end
                it "calls the root loader's added_child method if the root is not self" do
                    root_loader = flexmock(:on, Base)
                    root_loader.should_receive(:added_child).
                        once.
                        with(->(obj){ obj != root_loader && obj.kind_of?(Base) })
                    Base.new(root_loader)
                end
            end

            describe "#parse_project_text" do
                it "evals the text in the context of a new project object" do
                    project = loader.parse_project_text("node 'test'")
                    assert project.has_node_model?('test')
                end

                it "passes evaluates the text using the given path" do
                    e = assert_raises(RuntimeError) do
                        loader.parse_project_text("raise", path: '/a/file')
                    end
                    assert e.backtrace.first =~ /\/a\/file:1/
                end
            end

            describe "#project_model_from_name" do
                attr_reader :project_model
                attr_reader :typekit_model

                before do
                    mock = flexmock(self.loader, :strict)
                    mock.should_receive(:project_model_text_from_name).
                        with('test').and_return(['the model text', 'test_path'])
                    mock.should_receive(:parse_project_text).
                        with('the model text', path: 'test_path').
                        and_return(@project_model = Project.new(loader, name: 'test'))
                    mock.should_receive(:typekit_model_from_name).
                        with('test').and_return(@typekit_model = flexmock)
                    @loader = mock
                end
                it "parses the project's textual representation and returns it" do
                    assert_equal project_model, loader.project_model_from_name('test')
                    assert_equal typekit_model, project_model.typekit
                end

                it "raises if the returned project has the wrong name" do
                    flexmock(project_model, :strict).should_receive(:name).and_return('unexpected')
                    assert_raises(InternalError) do
                        loader.project_model_from_name('test')
                    end
                end

                it 'caches the loaded projects' do
                    loader.project_model_from_name('test')
                    assert_same project_model, loader.project_model_from_name('test')
                end

                it "registers the loaded project" do
                    loader.should_receive(:register_project_model).once.with(project_model)
                    loader.project_model_from_name('test')
                end
            end

            describe "#register_project_model" do
                attr_reader :project
                before do
                    @project = Project.new(loader, name: 'test')
                end
                it "raises AlreadyRegistered when attempting to register a project whose name was already loaded" do
                    loader.register_project_model(project)
                    assert_raises(AlreadyRegistered) do
                        loader.register_project_model(project)
                    end
                end

                it "registers on the root loader" do
                    loader = Base.new(root_loader = Base.new)
                    flexmock(root_loader, :strict).should_receive(:register_project_model).with(project).once
                    loader.register_project_model(project)
                end

                it "registers the project's node models" do
                    node_m = project.node 'test'
                    flexmock(loader, :strict).should_receive(:register_node_model).
                        once.with(node_m)
                    loader.register_project_model(project)
                end

                it "registers the project's deployment models" do
                    deployment_m = project.deployment 'test'
                    flexmock(loader, :strict).should_receive(:register_deployment_model).
                        once.with(deployment_m)
                    loader.register_project_model(project)
                end
            end

            describe "a project load callback" do
                attr_reader :project
                before do
                    @project = Project.new(loader, name: 'test')
                end

                it "is called on project registration" do
                    recorder = flexmock
                    recorder.should_receive(:called).with(project).once
                    loader.on_project_load { |p| recorder.called(p) }
                    loader.register_project_model(project)
                end

                it "is called for the already loaded projects when registered with initial_events" do
                    recorder = flexmock
                    loader.register_project_model(project)
                    recorder.should_receive(:called).with(project).once
                    loader.on_project_load { |p| recorder.called(p) }
                end

                it "is not called for the already loaded projects when registered without initial_events" do
                    recorder = flexmock
                    loader.register_project_model(project)
                    recorder.should_receive(:called).with(project).never
                    loader.on_project_load(initial_events: false) { |p| recorder.called(p) }
                end

                it "is deregistered by remove_project_load_callback" do
                    recorder = flexmock
                    recorder.should_receive(:called).with(project).never
                    callback_id = loader.on_project_load { |p| recorder.called(p) }
                    loader.remove_project_load_callback(callback_id)
                    loader.register_project_model(project)
                end
            end

            describe "#has_loaded_project?" do
                it "returns false for an unknown project" do
                    assert !loader.has_loaded_project?('test')
                end
                it "returns true for a registered project" do
                    p = Project.new(loader, name: 'test')
                    loader.register_project_model(p)
                    assert loader.has_loaded_project?('test')
                end
            end

            describe "#parse_typekit_text" do
                it "unmarshals the information into a Typekit object" do
                    metainfo_section = YAML.dump(Hash[
                        'name' => 'test',
                        'typelist' => ['/int', '/double'],
                        'interface_typelist' => ['/double']])
                    registry = ModelKit::Types::Registry.new
                    registry.create_null '/int'
                    registry.create_null '/double'
                    text = metainfo_section + "\n---\n" + registry.to_xml.to_s
                    typekit = loader.parse_typekit_text(text)
                    assert_equal 'test', typekit.name

                    int_t = typekit.registry.get('/int')
                    double_t = typekit.registry.get('/double')
                    assert_equal Set[int_t, double_t], typekit.typelist
                    assert_equal Set[double_t], typekit.interface_typelist
                end

                it "raises if the text does not contain a typelib XML document" do
                    metainfo_section = YAML.dump(Hash[
                        'name' => 'test', 'typelist' => [], 'interface_typelist' => []])
                    text = metainfo_section + "\n---\n"
                    assert_raises(ArgumentError) do
                        loader.parse_typekit_text(text)
                    end
                end
            end

            describe "#typekit_model_from_name" do
                attr_reader :loader, :typekit_model

                before do
                    mock = flexmock(self.loader, :strict)
                    mock.should_receive(:typekit_model_text_from_name).
                        with('test').and_return(['the model text', 'test_path'])
                    mock.should_receive(:parse_typekit_text).
                        with('the model text', path: 'test_path').
                        and_return(@typekit_model = Typekit.new(loader, name: 'test'))
                    @loader = mock
                end

                it "parses the textual representation and returns it" do
                    assert_equal typekit_model, loader.typekit_model_from_name('test')
                end

                it "raises if the returned typekit has the wrong name" do
                    flexmock(typekit_model, :strict).should_receive(:name).and_return('unexpected')
                    assert_raises(InternalError) do
                        loader.typekit_model_from_name('test')
                    end
                end

                it 'caches the loaded typekits' do
                    loader.typekit_model_from_name('test')
                    assert_same typekit_model, loader.typekit_model_from_name('test')
                end

                it "registers the loaded typekit" do
                    loader.should_receive(:register_typekit_model).once.with(typekit_model)
                    loader.typekit_model_from_name('test')
                end
            end

            describe "#register_typekit_model" do
                attr_reader :typekit
                before do
                    @typekit = Typekit.new(loader, name: 'test')
                end
                it "raises AlreadyRegistered when attempting to register a typekit whose name was already loaded" do
                    loader.register_typekit_model(typekit)
                    assert_raises(AlreadyRegistered) do
                        loader.register_typekit_model(typekit)
                    end
                end

                it "registers on the root loader" do
                    loader = Base.new(root_loader = Base.new)
                    flexmock(root_loader, :strict).should_receive(:register_typekit_model).with(typekit).once
                    loader.register_typekit_model(typekit)
                end

                it "registers the type-to-typekit mapping" do
                    typekit.create_null '/Test'
                    loader.register_typekit_model(typekit)
                    assert_equal Set[typekit], loader.imported_typekits_for('/Test', definition_typekits: false)

                end
            end

            describe "a typekit load callback" do
                attr_reader :typekit
                before do
                    @typekit = Typekit.new(loader, name: 'test')
                end

                it "is called on typekit registration" do
                    recorder = flexmock
                    recorder.should_receive(:called).with(typekit).once
                    loader.on_typekit_load { |p| recorder.called(p) }
                    loader.register_typekit_model(typekit)
                end

                it "is called for the already loaded typekits when registered with initial_events" do
                    recorder = flexmock
                    loader.register_typekit_model(typekit)
                    recorder.should_receive(:called).with(typekit).once
                    loader.on_typekit_load { |p| recorder.called(p) }
                end

                it "is not called for the already loaded typekits when registered without initial_events" do
                    recorder = flexmock
                    loader.register_typekit_model(typekit)
                    recorder.should_receive(:called).with(typekit).never
                    loader.on_typekit_load(initial_events: false) { |p| recorder.called(p) }
                end

                it "is deregistered by remove_typekit_load_callback" do
                    recorder = flexmock
                    recorder.should_receive(:called).with(typekit).never
                    callback_id = loader.on_typekit_load { |p| recorder.called(p) }
                    loader.remove_typekit_load_callback(callback_id)
                    loader.register_typekit_model(typekit)
                end
            end

            describe "#has_loaded_typekit?" do
                it "returns false for an unknown typekit" do
                    assert !loader.has_loaded_typekit?('test')
                end
                it "returns true for a registered typekit" do
                    p = Typekit.new(loader, name: 'test')
                    loader.register_typekit_model(p)
                    assert loader.has_loaded_typekit?('test')
                end
            end

            describe "#node_library_model_from_name" do
                it "loads the project and returns it" do
                    project = Project.new(loader, name: 'test')
                    project.node 'test'
                    loader.register_project_model(project)
                    assert_same project, loader.node_library_model_from_name('test')
                end
                it "raises ProjectNotFound if the returned project has no nodes" do
                    project = Project.new(loader, name: 'test')
                    loader.register_project_model(project)
                    assert_raises(ProjectNotFound) do
                        loader.node_library_model_from_name('test')
                    end
                end
            end

            describe "#node_model_from_name" do
                it "resolves the project name and loads it" do
                    project = Project.new(Base.new, name: 'test')
                    node_m = project.node 'TestNode'
                    # Do NOT register the project model, it would bypass
                    # resolution because of caches
                    flexmock(loader, :strict).should_receive(:find_project_name_from_node_model_name).with('TestNode').and_return('test')
                    flexmock(loader).should_receive(:project_model_from_name).with('test').
                        and_return { loader.register_project_model(project); project }
                    assert_same node_m, loader.node_model_from_name('TestNode')
                end

                it "raises InternalError if the loaded project does not provide the expected node" do
                    project = Project.new(loader, name: 'test')
                    loader.register_project_model(project)
                    flexmock(loader, :strict).should_receive(:find_project_name_from_node_model_name).with('TestNode').and_return('test')
                    assert_raises(InternalError) do
                        loader.node_model_from_name('TestNode')
                    end
                end

                it "resolves nodes that have already been registered" do
                    project = Project.new(loader, name: 'test')
                    node_m = project.node 'TestNode'
                    loader.register_project_model(project)
                    assert_same node_m, loader.node_model_from_name('TestNode')
                end

                it "raises NodeModelNotFound if the node model cannot be found" do
                    flexmock(loader, :strict).should_receive(:find_project_name_from_node_model_name).with('TestNode').and_return(nil)
                    assert_raises(NodeModelNotFound) do
                        loader.node_model_from_name('TestNode')
                    end
                end
            end

            describe "#register_node_model" do
                it "registers the node models" do
                    node_m = Node.new_submodel name: 'test'
                    loader = Base.new
                    loader.register_node_model(node_m)
                    assert_same node_m, loader.node_model_from_name('test')
                end

                it "registers on the root loader" do
                    loader = Base.new(root_loader = Base.new)
                    node_m = Node.new_submodel name: 'test'
                    flexmock(root_loader, :strict).should_receive(:register_node_model).with(node_m).once
                    loader.register_node_model(node_m)
                end
            end

            describe "#register_deployment_model" do
                it "registers the deployment models" do
                    loader = Base.new
                    deployment_m = Deployment.new(loader, name: 'test')
                    loader.register_deployment_model(deployment_m)
                    assert_same deployment_m, loader.deployment_model_from_name('test')
                end

                it "registers on the root loader" do
                    loader = Base.new(root_loader = Base.new)
                    deployment_m = Deployment.new(loader, name: 'test')
                    flexmock(root_loader, :strict).should_receive(:register_deployment_model).with(deployment_m).once
                    loader.register_deployment_model(deployment_m)
                end
            end

            describe "#deployment_model_from_name" do
                it "resolves the project name and loads it" do
                    project = Project.new(Base.new, name: 'test')
                    deployment_m = project.deployment 'test_deployment'
                    # Do NOT register the project model, it would bypass
                    # resolution because of caches
                    flexmock(loader, :strict).should_receive(:find_project_name_from_deployment_model_name).with('test_deployment').and_return('test')
                    flexmock(loader).should_receive(:project_model_from_name).with('test').
                        and_return { loader.register_project_model(project); project }
                    assert_same deployment_m, loader.deployment_model_from_name('test_deployment')
                end

                it "raises InternalError if the loaded project does not provide the expected deployment" do
                    project = Project.new(loader, name: 'test')
                    loader.register_project_model(project)
                    flexmock(loader, :strict).should_receive(:find_project_name_from_deployment_model_name).with('test_deployment').and_return('test')
                    assert_raises(InternalError) do
                        loader.deployment_model_from_name('test_deployment')
                    end
                end

                it "resolves deployments that have already been registered" do
                    project = Project.new(loader, name: 'test')
                    deployment_m = project.deployment 'test_deployment'
                    loader.register_project_model(project)
                    assert_same deployment_m, loader.deployment_model_from_name('test_deployment')
                end

                it "raises DeploymentModelNotFound if the deployment model cannot be found" do
                    flexmock(loader, :strict).should_receive(:find_project_name_from_deployment_model_name).with('test_deployment').and_return(nil)
                    assert_raises(DeploymentModelNotFound) do
                        loader.deployment_model_from_name('test_deployment')
                    end
                end
            end

            describe "#deployed_node_model_from_name" do
                it "resolves the project name and loads it" do
                    project = Project.new(Base.new, name: 'test')
                    node_m = project.node 'TestNode'
                    deployment_m = project.deployment 'test_deployment'
                    deployed_node_m = deployment_m.node 'test_node', "TestNode"

                    # Do NOT register the project model, it would bypass
                    # resolution because of caches
                    flexmock(loader, :strict).should_receive(:find_deployment_model_names_from_deployed_node_name).with('test_node').and_return(['test_deployment'])
                    flexmock(loader).should_receive(:deployment_model_from_name).with('test_deployment').
                        and_return { loader.register_project_model(project); deployment_m }
                    assert_same deployed_node_m, loader.deployed_node_model_from_name('test_node')
                end

                it "raises InternalError if the loaded deployment does not provide the expected deployed node" do
                    project = Project.new(loader, name: 'test')
                    project.deployment 'test_deployment'
                    loader.register_project_model(project)
                    flexmock(loader, :strict).should_receive(:find_deployment_model_names_from_deployed_node_name).with('test_node').and_return(['test_deployment'])
                    assert_raises(InternalError) do
                        loader.deployed_node_model_from_name('test_node')
                    end
                end

                it "resolves deployed nodes that have already been registered" do
                    project = Project.new(loader, name: 'test')
                    node_m = project.node 'TestNode'
                    deployment_m = project.deployment 'test_deployment'
                    deployed_node_m = deployment_m.node 'test_node', "TestNode"
                    loader.register_project_model(project)
                    assert_equal Set['test_deployment'], loader.find_deployment_model_names_from_deployed_node_name('test_node')
                    assert_same deployed_node_m, loader.deployed_node_model_from_name('test_node')
                end

                it "raises DeployedNodeModelNotFound if the deployment model cannot be found" do
                    flexmock(loader, :strict).should_receive(:find_deployment_model_names_from_deployed_node_name).with('test_node').and_return(Set.new)
                    assert_raises(DeployedNodeModelNotFound) do
                        loader.deployed_node_model_from_name('test_node')
                    end
                end

                it "raises AmbiguousdeployedNodeName if the deployed node can be found in more than one deployment" do
                    flexmock(loader, :strict).should_receive(:find_deployment_model_names_from_deployed_node_name).with('test_node').and_return(['a', 'b'])
                    assert_raises(AmbiguousDeployedNodeName) do
                        loader.deployed_node_model_from_name('test_node')
                    end
                end

                it "allows to specify the deployment name explicitely" do
                    project = Project.new(Base.new, name: 'test')
                    node_m = project.node 'TestNode'
                    deployment_m = project.deployment 'test_deployment'
                    deployed_node_m = deployment_m.node 'test_node', "TestNode"
                    flexmock(loader).should_receive(:deployment_model_from_name).with('test_deployment').and_return(deployment_m)
                    flexmock(loader, :strict).should_receive(:find_deployment_model_names_from_deployed_node_name).never
                    assert_same deployed_node_m,
                        loader.deployed_node_model_from_name('test_node', deployment_name: 'test_deployment')
                end

                it "raises ArgumentError if an explicitely given deployment does not contain the expected deployed node" do
                    project = Project.new(Base.new, name: 'test')
                    node_m = project.node 'TestNode'
                    deployment_m = project.deployment 'test_deployment'
                    flexmock(loader).should_receive(:deployment_model_from_name).with('test_deployment').and_return(deployment_m)
                    flexmock(loader, :strict).should_receive(:find_deployment_model_names_from_deployed_node_name).never
                    assert_raises(ArgumentError) do
                        loader.deployed_node_model_from_name('test_node', deployment_name: 'test_deployment')
                    end
                end
            end

            describe "#resolve_type" do
                it "returns the type in self that maps to the given name" do
                    int_t = loader.registry.create_null '/int'
                    assert_same int_t, loader.resolve_type('/int')
                end

                it "returns the type in self that maps to the given type" do
                    int_t = loader.registry.create_null '/int'
                    assert_same int_t, loader.resolve_type(flexmock(name: '/int'))
                end
            end

            describe "#imported_typekits_for" do
                describe "definition_typekits: true" do
                    it "narrows the typekits to the ones that define the type" do
                        def_typekit = Typekit.new(loader, name: 'def')
                        def_typekit.create_null '/int'
                        typekit = Typekit.new(loader, name: 'tk')
                        typekit.registry.create_null '/int'
                        loader.register_typekit_model(def_typekit)
                        loader.register_typekit_model(typekit)
                        assert_equal Set[def_typekit], loader.imported_typekits_for('/int')
                    end

                    it "raises if the type exists in some typekits registries, but none of the typekits define the type" do
                        typekit = Typekit.new(loader, name: 'tk')
                        typekit.registry.create_null '/int'
                        loader.register_typekit_model(typekit)
                        assert_raises(DefinitionTypekitNotFound) do
                            loader.imported_typekits_for('/int', definition_typekits: true)
                        end
                    end
                end

                describe "definition_typekits: false" do
                    it "returns all typekits that have the type" do
                        t0 = Typekit.new(loader, name: 'test0')
                        t0.registry.create_null '/int'
                        t1 = Typekit.new(loader, name: 'test1')
                        t1.create_null '/int'
                        loader.register_typekit_model(t0)
                        loader.register_typekit_model(t1)
                        assert_equal Set[t0, t1], loader.imported_typekits_for('/int', definition_typekits: false)
                    end

                    it "can be given a type by object" do
                        t0 = Typekit.new(loader, name: 'test0')
                        t0.registry.create_null '/int'
                        loader.register_typekit_model(t0)
                        assert_equal Set[t0], loader.imported_typekits_for(flexmock(name: '/int'), definition_typekits: false)
                    end
                    
                    it "raises if the type is not defined by any typekit" do
                        assert_raises(DefinitionTypekitNotFound) do
                            loader.imported_typekits_for(flexmock(name: '/int'), definition_typekits: false)
                        end
                    end
                end
            end

            describe "#resolve_interface_type" do
                it "resolves the type" do
                    typekit = Typekit.new(name: 'test')
                    int_t = typekit.create_interface_null '/int'
                    loader.register_typekit_model(typekit)
                    assert_same loader.registry.get('/int'), loader.resolve_interface_type('/int')
                end
                it "raises NotInterfaceType if the type can be resolved but is not an interface type" do
                    typekit = Typekit.new(name: 'test')
                    typekit.create_null '/int'
                    loader.register_typekit_model(typekit)

                    assert_raises(NotInterfaceType) do
                        loader.resolve_interface_type('/int')
                    end
                end

                it "returns the type in self that maps to the given type" do
                    int_t = loader.registry.create_null '/int'
                    assert_same int_t, loader.resolve_type(flexmock(name: '/int'))
                end
            end

            describe "#find_project_name_from_node_model_name" do
                attr_reader :project
                before do
                    @project = Project.new(loader, name: 'test')
                    project.node 'TestNode'
                    loader.register_project_model(project)
                end

                it "returns the mapping for loaded projects" do
                    assert_equal 'test', loader.find_project_name_from_node_model_name('TestNode')
                end

                it "returns nil if no project defines the required node" do
                    assert !loader.find_project_name_from_node_model_name('Bla')
                end
            end
        end
    end
end

