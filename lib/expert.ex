defmodule Expert do

  @engine :beer_expert

  def start do
    {:ok, _} = :seresye.start(@engine)
    Facts.add_to(@engine)
    Rules.add_to(@engine)
  end

  def stop do
    :ok = :seresye.stop(@engine)
  end

  def tell(beer_name, facts) when is_list(facts) do
    for fact <- facts, do: tell(beer_name, fact)
  end

  def tell(beer_name, fact) when is_tuple(fact) do
    :seresye.assert(@engine, {:beer, beer_name, fact})
  end

  def ask(beer_name) do
    :seresye.query_kb(@engine, {:beer_match, beer_name, :'_'})
  end
  
end

defmodule Facts do

  @facts [{:beer_style, 1, 'Berlinerweisse', {:abv, 2.5, 3.6}},
          {:beer_style, 1, 'Berlinerweisse', {:srm, 2, 4}},
          {:beer_style, 1, 'Berlinerweisse', {:ibu, 3, 12}},
          {:beer_style, 1, 'Berlinerweisse', {:original_gravity, 1.026, 1.036}},
          {:beer_style, 1, 'Berlinerweisse', {:final_gravity, 1.006, 1.009}}]

  def add_to(engine) do
    :seresye.assert(engine, @facts)
  end

end

defmodule Rules do
  require Logger

  def add_to(engine) do 
    :seresye.add_rules(engine, [{:'Elixir.Rules', :abv_categorise},
                                {:'Elixir.Rules', :remove_abv_categorise}])
  end
  
  def abv_categorise(
    engine,
    {:beer, beerName, {:abv, abv}}, 
    {:beer_style, styleNumber, styleName, {:abv, abvLower, abvUpper}}) 
  when abvLower <= abv and abv <= abvUpper do
    Logger.debug("Expert thinks #{beerName} could be a #{styleName}.")
    :seresye_engine.assert(engine, {:beer_match, beerName, {:beer_style, styleNumber, styleName}})
  end

  def remove_abv_categorise(
    engine,
    {:beer, beerName, {:abv, abv}}, 
    {:beer_style, styleNumber, styleName, {:abv, abvLower, abvUpper}},
    {:beer_match, beerName, {:beer_style, styleNumber, styleName}})
  when abv < abvLower or abvUpper < abv do
      Logger.debug("Expert no longer thinks #{beerName} could be a #{styleName} as ABV #{abv} is not between #{abvLower} and #{abvUpper}.")
      :seresye_engine.retract(engine, [{:beer_match, beerName, {:beer_style, styleNumber, styleName}}])
      engine
  end

end