defmodule ExunitFixturesTest do
  use ExUnitFixtures

  use ExUnit.Case
  doctest ExUnitFixtures

  deffixture simple do
    "simple"
  end

  deffixture not_so_simple(simple) do
    {:not_so_simple, simple}
  end

  deffixture fixture_with_context(context) do
    context.fun_things
  end

  deffixture ref do
    make_ref()
  end

  deffixture ref_child1(ref) do
    ref
  end

  deffixture ref_child2(ref) do
    ref
  end

  deffixture module_fixture(), scope: :module do
    Agent.update(:module_counter, fn i -> i + 1 end)

    teardown :module, fn ->
      Agent.update(:module_counter, fn _ -> nil end)
    end

    :woo_modules
  end

  deffixture test_fixture_with_module_fixture(module_fixture) do
    module_fixture
  end

  deffixture session_fixture(), scope: :session do
    Agent.update(:session_counter, fn i -> i + 1 end)

    :woo_sessions
  end

  deffixture module_fixture_with_session_dep(session_fixture) do
    session_fixture
  end

  deffixture test_dep_with_session_dep(module_fixture_with_session_dep) do
    module_fixture_with_session_dep
  end

  deffixture autouse_fixture, autouse: true do
    :automagic
  end

  register_fixture :manual_no_dep_fixture
  def manual_no_dep_fixture do
    "manual_no_dep"
  end

  def manual_dep_fixture(_manual_no_dep_fixture) do
    "manual_dep"
  end
  register_fixture :manual_dep_fixture, [:manual_no_dep_fixture]

  setup_all do
    {:ok, %{setup_all_ran: true}}
  end

  setup context do
    {:ok, %{setup_ran: true, setup_all_ran: context.setup_all_ran}}
  end

  test "deffixture generates a function that can create a fixture" do
    assert simple() == "simple"
  end

  test "deffixture adds the fixture to @fixtures" do
    expected = %ExUnitFixtures.FixtureDef{
      name: :simple,
      func: {ExunitFixturesTest, :simple},
      qualified_name: :"Elixir.ExunitFixturesTest.simple"
    }
    assert expected in @fixtures
  end

  @tag fixtures: [:simple]
  test "tagging with fixtures loads in the fixtures", context do
    assert context.simple == "simple"
  end

  test "not tagging with fixtures loads in nothing", context do
    refute Map.has_key?(context, :simple)
    refute Map.has_key?(context, :complex)
  end

  @tag fixtures: [:not_so_simple]
  test "deffixture with dependencies", context do
    assert context.not_so_simple == {:not_so_simple, "simple"}
    refute Map.has_key?(context, :simple)
  end

  @tag fixtures: [:not_so_simple, :simple]
  test "deffixture with dependencies & parent dependencies", context do
    assert context.not_so_simple == {:not_so_simple, "simple"}
    assert context.simple == "simple"
  end

  @tag fixtures: [:ref_child1, :ref_child2, :ref]
  test "fixture dependencies only created once", context do
    assert context.ref_child1 == context.ref
    assert context.ref_child2 == context.ref
  end

  @tag fixtures: [:simple]
  test "other setup functions still run", context do
    assert context.setup_ran
  end

  @tag fixtures: [:fixture_with_context]
  @tag fun_things: "Clowns"
  test "fixtures can access the test context", context do
    assert context.fixture_with_context == "Clowns"
  end

  @tag fixtures: [:module_fixture]
  test "module level fixtures can be accessed", context do
    assert context.module_fixture == :woo_modules
  end


  @tag fixtures: [:test_fixture_with_module_fixture]
  test "test fixtures can depend on module level fixtures", context do
    assert context.test_fixture_with_module_fixture == :woo_modules
  end

  @tag fixtures: [:test_fixture_with_module_fixture]
  test "module fixtures are only initialised once" do
    assert Agent.get(:module_counter, fn x -> x end) == 1
  end

  @tag fixtures: [:module_fixture]
  test "module fixtures are not freed till module is finished" do
    assert Agent.get(:module_counter, fn x -> x end) == 1
  end

  @tag fixtures: [:session_fixture]
  test "session fixtures can be used", %{session_fixture: fix} do
    assert fix == :woo_sessions
  end

  @tag fixtures: [:test_dep_with_session_dep,
                  :module_fixture_with_session_dep]
  test "fixtures can depend on session fixtures", context do
    assert context.test_dep_with_session_dep == :woo_sessions
    assert context.module_fixture_with_session_dep == :woo_sessions
  end

  @tag fixtures: [:session_fixture]
  test "session fixtures are only initialised once" do
    assert Agent.get(:session_counter, fn x -> x end) == 1
  end

  test "other setup_all functions still run", context do
    assert context.setup_all_ran
  end

  test "autouse fixture is used when no fixtures requested", context do
    assert context.autouse_fixture == :automagic
  end

  @tag fixtures: [:simple]
  test "autouse fixture is used when a fixture is requested", context do
    assert context.autouse_fixture == :automagic
  end

  @tag fixtures: [:autouse_fixture]
  test "asking for an autouse fixture is ok", context do
    assert context.autouse_fixture == :automagic
  end

  @tag fixtures: [:manual_dep_fixture, :manual_no_dep_fixture]
  test "manual fixtures", context do
    assert context.manual_dep_fixture == "manual_dep"
    assert context.manual_no_dep_fixture == "manual_no_dep"
  end
end
