defmodule Expert do

  @engine :beer_expert

  def start do
    {:ok, _} = :seresye.start(@engine)
    Facts.add_to(@engine)
    Rules.add_to(@engine)
  end

  def tell(beer_name, facts) when is_list(facts) do
    for fact <- facts, do: tell(beer_name, fact)
  end

  def tell(beer_name, fact) when is_tuple(fact) do
    :seresye.assert(@engine, {:beer, beer_name, fact})
  end

  def ask(beer_name) do
    :seresye.assert(@engine, {:beer, beer_name, {:beer_style, :'_', :'_'}})
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
    :seresye.add_rule(engine, {:'Elixir.Rules', :abv_categorise})
    :seresye.add_rule(engine, {:'Elixir.Rules', :mother})
  end
  
  def abv_categorise(
    engine,
    {:beer, beerName, {:abv, abv}}, 
    {:beer_style, styleNumber, styleName, {:abv, abvLower, abvUpper}}) 
  when abvLower <= abv and abv <= abvUpper do
    Logger.debug("Expert thinks #{beerName} could be a #{styleName}.")
    :seresye.assert(engine, {:lol, 'wow'})
  end

  def mother(engine, {:female, x}, {:parent, x, y}), 
    do: :seresye.assert(engine, {:mother, x, y})

end