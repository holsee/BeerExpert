defmodule ExpertTest do
  use ExUnit.Case

  require Logger

  @engine :beer_expert

  setup do
    Expert.stop
    :ok = Expert.start
  end

  test "rules have been added" do
    berliner_rules = :seresye.query_kb(@engine, {:beer_style, 1, 'Berliner Weisse', :'_'})
    assert 8 == Enum.count(berliner_rules)
  end

  test "tell expert about known beer and ask if it knows what it could be" do
    # http://www.saintarnold.com/beers/boiler_room.html
    expected_style = [{:beer_match, 'Boiler Room', {:beer_style, 19, 'Scottish Light 60/-'}}, 
                      {:beer_match, 'Boiler Room', {:beer_style, 1, 'Berliner Weisse'}},
                      {:beer_match, 'Boiler Room', {:beer_style, 20, 'English Mild'}}]

    Expert.tell 'Boiler Room', {:abv, 2.9}

    assert expected_style == Expert.ask 'Boiler Room'
  end

  test "tell expert new info about beer to narrow possibilities" do
    expected_style = [{:beer_match, 'Boiler Room', {:beer_style, 1, 'Berliner Weisse'}}]

    Expert.tell 'Boiler Room', {:abv, 2.9}
    Expert.tell 'Boiler Room', {:ibu, 7}

    assert expected_style == Expert.ask 'Boiler Room'
  end

  test "tell expert new info about beer should remove existing info if provided" do
    expected_beer_fact = [{:beer, 'Boiler Room', {:ibu, 7}}]

    Expert.tell 'Boiler Room', {:ibu, 6}
    Expert.tell 'Boiler Room', {:ibu, 7}

    ibu_facts = :seresye.query_kb(@engine, {:beer, 'Boiler Room', :'_'})

    assert expected_beer_fact == ibu_facts
  end



end
