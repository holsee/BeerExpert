defmodule SeresyeTest do
  use ExUnit.Case

  require Logger

  @engine :test_engine
  @rules [{:'Elixir.TestRules', :rule_foobar}]

  test "start seresye" do
    assert  {:ok, _} = :seresye.start(@engine)
    :seresye.stop(@engine)
  end

  test "assert facts" do
    {:ok, _} = :seresye.start(@engine)

    facts = [{:foo, 'bar'},
             {:foo, 'buzz'},
             {:foo, 'bazz'}]

    :seresye.assert(@engine, facts)

    results = :seresye.query_kb(@engine, {:foo, :'_'})

    assert results == Enum.reverse(facts)

    :seresye.stop(@engine)
  end

  test "add rules" do
    {:ok, _} = :seresye.start(@engine)

    assert :ok = :seresye.add_rules(@engine, @rules)
    
    :seresye.stop(@engine)
  end

  test "invoke rules" do
    {:ok, _} = :seresye.start(@engine)

    :seresye.add_rules(@engine, @rules)

    :seresye.assert(@engine, {:foo, 'xxx'})
    :seresye.assert(@engine, {:bar, 'xxx'})

    assert [{:foobar, 'xxx'}] == 
           :seresye.query_kb(@engine, {:foobar, :'_'})

    :seresye.assert(@engine, {:foo, 'yyy'})
    :seresye.assert(@engine, {:bar, 'yyy'})

    assert [{:foobar, 'yyy'}, {:foobar, 'xxx'}] == 
           :seresye.query_kb(@engine, {:foobar, :'_'})
    
    :seresye.stop(@engine)
  end

end
