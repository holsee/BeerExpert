defmodule ExpertTest do
  use ExUnit.Case

  require Logger

  @engine :beer_expert

  setup do
    Expert.stop
    :ok = Expert.start
  end

  test "rules have been added" do
    berliner_rules = :seresye.query_kb(@engine, {:beer_style, 1, 'Berlinerweisse', :'_'})
    assert 5 == Enum.count(berliner_rules)
  end

  test "tell expert about known beer and ask if it knows what it could be" do
    # http://www.saintarnold.com/beers/boiler_room.html
    expected_style = [{:beer_match, 'Boiler Room', {:beer_style, 1, 'Berlinerweisse'}}]

    Expert.tell 'Boiler Room', {:abv, 2.9}

    assert expected_style == Expert.ask 'Boiler Room'
  end

end
