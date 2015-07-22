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
    # Load prior knowledge about given beer
    existing_facts = :seresye.query_kb(@engine, {:beer, beer_name, :'_'})
    :io.format("existing_facts: ~p\n", [existing_facts])

    # Remove existing facts matching given key
    remove_existing(beer_name, fact)

    # Find out what Expert has already figured out to be a match when last fact added
    existing_matches = :seresye.query_kb(@engine, {:beer_match, beer_name, :'_'})
    :io.format("existing_matches: ~p\n", [existing_matches])

    # Remove them from the engine as we are going to generate new matches
    remove_exisitng_matches(beer_name)

    # Tell Expert about new fact, which may generate new matches
    :seresye.assert(@engine, {:beer, beer_name, fact})

    # If this was the first fact, then all matches are valid
    # Otherwise we need to find the intersection of the results like so:
    if(Enum.count(existing_facts) > 0) do
        # Find the new matches, from last fact execution
        new_matches = :seresye.query_kb(@engine, {:beer_match, beer_name, :'_'})
        :io.format("new_matches: ~p\n", [new_matches])

        # Remove them as we can now refine them base on existing matches from other facts
        remove_exisitng_matches(beer_name)
        
        # We intersect existing matches against the new matches
        e = Enum.into(existing_matches, HashSet.new)
        n = Enum.into(new_matches, HashSet.new)
        r = Set.intersection(e, n)

        # Store them in the engine!
        for new <- r, 
            do: :seresye.assert(@engine, new)
    end
  end

  def ask(beer_name) do
    :seresye.query_kb(@engine, {:beer_match, beer_name, :'_'})
  end

  defp remove_exisitng_matches(beer_name) do
    matches = :seresye.query_kb(@engine, {:beer_match, beer_name, :'_'})

    for old_match <- matches do
      :io.format("retract existing match: ~p\n", [old_match])
      :seresye.retract(@engine, old_match)
    end
  end

  defp remove_existing(beer_name, {key, value}) do
    existing_facts = :seresye.query_kb(@engine, {:beer, beer_name, :'_'}) 

    for old_fact <- existing_facts, {:beer, _, {key, _}} = old_fact do
      :io.format("retracting fact: ~p\n", [old_fact])
      :seresye.retract(@engine, old_fact)
    end
  end
  
end

defmodule Rules do
  require Logger

  def add_to(engine) do 
    :seresye.add_rules(engine, [
      {:'Elixir.Rules', :abv_categorise},
      {:'Elixir.Rules', :ibu_categorise},
      {:'Elixir.Rules', :beer_category}])
  end

  def abv_categorise(
    engine,
    {:beer, beerName, {:abv, abv}}, 
    {:beer_style, styleNumber, styleName, {:abv, abvLower, abvUpper}}) 
  when abvLower <= abv and abv <= abvUpper do
    Logger.debug("abv_categorise => Expert thinks #{beerName} could be a #{styleName} as abv #{abv} is between #{abvLower} & #{abvUpper}")

    :seresye_engine.assert(engine, {:beer_match, beerName, {:beer_style, styleNumber, styleName}})
  end

  def ibu_categorise(
    engine,
    {:beer, beerName, {:ibu, ibu}}, 
    {:beer_style, styleNumber, styleName, {:ibu, ibuLower, ibuUpper}}) 
  when ibuLower <= ibu and ibu <= ibuUpper do
    Logger.debug("ibu_categorise => Expert thinks #{beerName} could be a #{styleName} as ibu #{ibu} is between #{ibuLower} & #{ibuUpper}")

    :seresye_engine.assert(engine, {:beer_match, beerName, {:beer_style, styleNumber, styleName}})
  end

  def beer_category(
    engine,
    {:beer, beerName, {:category, category}}, 
    {:beer_style, styleNumber, styleName, {:catgeory, category}}) do
    Logger.debug("ibu_categorise => Expert thinks #{beerName} could be a #{styleName} as category #{category} is a match")

    :seresye_engine.assert(engine, {:beer_match, beerName, {:beer_style, styleNumber, styleName}})
  end

end

defmodule Facts do

  @facts [
    {:beer_style, 1, 'Berliner Weisse', {:catgeory, "Ale"}},
    {:beer_style, 1, 'Berliner Weisse', {:sub_category, "Wheat Beer"}},
    {:beer_style, 1, 'Berliner Weisse', {:original_gravity, 1.026, 1.036}},
    {:beer_style, 1, 'Berliner Weisse', {:final_gravity, 1.006, 1.009}},
    {:beer_style, 1, 'Berliner Weisse', {:abv, 2.5, 3.6}},
    {:beer_style, 1, 'Berliner Weisse', {:ibu, 3, 12}},
    {:beer_style, 1, 'Berliner Weisse', {:srm, 2, 4}},
    {:beer_style, 1, 'Berliner Weisse', {:wiki, 'http://en.wikipedia.org/wiki/Berliner_Weisse'}},

    {:beer_style, 4, 'Belgian White', {:catgeory, "Ale"}},
    {:beer_style, 4, 'Belgian White', {:sub_category, "Wheat Beer"}},
    {:beer_style, 4, 'Belgian White', {:original_gravity, 1.042, 1.055}},
    {:beer_style, 4, 'Belgian White', {:final_gravity, 1.008, 1.012}},
    {:beer_style, 4, 'Belgian White', {:abv, 4.5, 5.5}},
    {:beer_style, 4, 'Belgian White', {:ibu, 15, 28}},
    {:beer_style, 4, 'Belgian White', {:srm, 2, 4}},
    {:beer_style, 4, 'Belgian White', {:wiki, 'http://en.wikipedia.org/wiki/Wheat_beer#Witbier'}},

    {:beer_style, 7, 'American Wheat', {:catgeory, "Ale"}},
    {:beer_style, 7, 'American Wheat', {:sub_category, "Wheat Beer"}},
    {:beer_style, 7, 'American Wheat', {:original_gravity, 1.035, 1.055}},
    {:beer_style, 7, 'American Wheat', {:final_gravity, 1.008, 1.018}},
    {:beer_style, 7, 'American Wheat', {:abv, 3.5, 5.0}},
    {:beer_style, 7, 'American Wheat', {:ibu, 5, 20}},
    {:beer_style, 7, 'American Wheat', {:srm, 2, 8}},
    {:beer_style, 7, 'American Wheat', {:wiki, 'http://www.brewingtechniques.com/library/backissues/issue1.1/bergen.html'}},

    {:beer_style, 14, 'Weizenbier', {:catgeory, "Ale"}},
    {:beer_style, 14, 'Weizenbier', {:sub_category, "Wheat Beer"}},
    {:beer_style, 14, 'Weizenbier', {:original_gravity, 1.040, 1.056}},
    {:beer_style, 14, 'Weizenbier', {:final_gravity, 1.008, 1.016}},
    {:beer_style, 14, 'Weizenbier', {:abv, 4.3, 5.6}},
    {:beer_style, 14, 'Weizenbier', {:ibu, 8, 15}},
    {:beer_style, 14, 'Weizenbier', {:srm, 3, 9}},
    {:beer_style, 14, 'Weizenbier', {:wiki, 'http://en.wikipedia.org/wiki/Weizenbier'}},

    {:beer_style, 27, 'Dunkelweizen', {:catgeory, "Ale"}},
    {:beer_style, 27, 'Dunkelweizen', {:sub_category, "Wheat Beer"}},
    {:beer_style, 27, 'Dunkelweizen', {:original_gravity, 1.048, 1.056}},
    {:beer_style, 27, 'Dunkelweizen', {:final_gravity, 1.008, 1.016}},
    {:beer_style, 27, 'Dunkelweizen', {:abv, 4.5, 6.0}},
    {:beer_style, 27, 'Dunkelweizen', {:ibu, 10, 15}},
    {:beer_style, 27, 'Dunkelweizen', {:srm, 17, 23}},
    {:beer_style, 27, 'Dunkelweizen', {:wiki, 'http://en.wikipedia.org/wiki/Dunkelweizen'}},

    {:beer_style, 41, 'Weizenbock', {:catgeory, "Ale"}},
    {:beer_style, 41, 'Weizenbock', {:sub_category, "Wheat Beer"}},
    {:beer_style, 41, 'Weizenbock', {:original_gravity, 1.066, 1.080}},
    {:beer_style, 41, 'Weizenbock', {:final_gravity, 1.016, 1.028}},
    {:beer_style, 41, 'Weizenbock', {:abv, 6.5, 9.6}},
    {:beer_style, 41, 'Weizenbock', {:ibu, 12, 25}},
    {:beer_style, 41, 'Weizenbock', {:srm, 10, 30}},
    {:beer_style, 41, 'Weizenbock', {:wiki, 'http://en.wikipedia.org/wiki/Weizenbock'}},

    {:beer_style, 2, 'Lambic', {:catgeory, "Ale"}},
    {:beer_style, 2, 'Lambic', {:sub_category, "Lambic & Sour"}},
    {:beer_style, 2, 'Lambic', {:original_gravity, 1.044, 1.056}},
    {:beer_style, 2, 'Lambic', {:final_gravity, 1.006, 1.012}},
    {:beer_style, 2, 'Lambic', {:abv, 4.7, 6.4}},
    {:beer_style, 2, 'Lambic', {:ibu, 5, 15}},
    {:beer_style, 2, 'Lambic', {:srm, 4, 15}},
    {:beer_style, 2, 'Lambic', {:wiki, 'http://en.wikipedia.org/wiki/Lambic'}},

    {:beer_style, 5, 'Gueuze', {:catgeory, "Ale"}},
    {:beer_style, 5, 'Gueuze', {:sub_category, "Lambic & Sour"}},
    {:beer_style, 5, 'Gueuze', {:original_gravity, 1.044, 1.056}},
    {:beer_style, 5, 'Gueuze', {:final_gravity, 1.006, 1.012}},
    {:beer_style, 5, 'Gueuze', {:abv, 4.7, 6.4}},
    {:beer_style, 5, 'Gueuze', {:ibu, 5, 15}},
    {:beer_style, 5, 'Gueuze', {:srm, 4, 15}},
    {:beer_style, 5, 'Gueuze', {:wiki, 'http://en.wikipedia.org/wiki/Gueuze'}},

    {:beer_style, 8, 'Faro', {:catgeory, "Ale"}},
    {:beer_style, 8, 'Faro', {:sub_category, "Lambic & Sour"}},
    {:beer_style, 8, 'Faro', {:original_gravity, 1.040, 1.056}},
    {:beer_style, 8, 'Faro', {:final_gravity, 1.006, 1.012}},
    {:beer_style, 8, 'Faro', {:abv, 4.5, 5.5}},
    {:beer_style, 8, 'Faro', {:ibu, 5, 15}},
    {:beer_style, 8, 'Faro', {:srm, 4, 15}},
    {:beer_style, 8, 'Faro', {:wiki, 'http://en.wikipedia.org/wiki/Lambic#Faro'}},

    # Beer Fruit Beer has SRM N/A! Defaulting Range 0-100!
    {:beer_style, 15, 'Fruit Beer', {:catgeory, "Ale"}},
    {:beer_style, 15, 'Fruit Beer', {:sub_category, "Lambic & Sour"}},
    {:beer_style, 15, 'Fruit Beer', {:original_gravity, 1.040, 1.072}},
    {:beer_style, 15, 'Fruit Beer', {:final_gravity, 1.008, 1.016}},
    {:beer_style, 15, 'Fruit Beer', {:abv, 4.7, 7.0}},
    {:beer_style, 15, 'Fruit Beer', {:ibu, 15, 21}},
    {:beer_style, 15, 'Fruit Beer', {:srm, 0, 100}},
    {:beer_style, 15, 'Fruit Beer', {:wiki, 'http://en.wikipedia.org/wiki/Lambic#Fruit'}},

    {:beer_style, 28, 'Flanders Red', {:catgeory, "Ale"}},
    {:beer_style, 28, 'Flanders Red', {:sub_category, "Lambic & Sour"}},
    {:beer_style, 28, 'Flanders Red', {:original_gravity, 1.042, 1.060}},
    {:beer_style, 28, 'Flanders Red', {:final_gravity, 1.008, 1.016}},
    {:beer_style, 28, 'Flanders Red', {:abv, 4.0, 5.8}},
    {:beer_style, 28, 'Flanders Red', {:ibu, 14, 25}},
    {:beer_style, 28, 'Flanders Red', {:srm, 10, 16}},
    {:beer_style, 28, 'Flanders Red', {:wiki, 'http://en.wikipedia.org/wiki/Flanders_red_ale'}},

    {:beer_style, 42, 'Oud Bruin', {:catgeory, "Ale"}},
    {:beer_style, 42, 'Oud Bruin', {:sub_category, "Lambic & Sour"}},
    {:beer_style, 42, 'Oud Bruin', {:original_gravity, 1.042, 1.060}},
    {:beer_style, 42, 'Oud Bruin', {:final_gravity, 1.008, 1.016}},
    {:beer_style, 42, 'Oud Bruin', {:abv, 4.0, 6.5}},
    {:beer_style, 42, 'Oud Bruin', {:ibu, 14, 30}},
    {:beer_style, 42, 'Oud Bruin', {:srm, 12, 20}},
    {:beer_style, 42, 'Oud Bruin', {:wiki, 'http://en.wikipedia.org/wiki/Oud_bruin'}},

    {:beer_style, 3, 'Belgian Gold Ale', {:catgeory, "Ale"}},
    {:beer_style, 3, 'Belgian Gold Ale', {:sub_category, "Belgian Ale"}},
    {:beer_style, 3, 'Belgian Gold Ale', {:original_gravity, 1.065, 1.085}},
    {:beer_style, 3, 'Belgian Gold Ale', {:final_gravity, 1.014, 1.020}},
    {:beer_style, 3, 'Belgian Gold Ale', {:abv, 7.0, 9.0}},
    {:beer_style, 3, 'Belgian Gold Ale', {:ibu, 25, 35}},
    {:beer_style, 3, 'Belgian Gold Ale', {:srm, 4, 6}},
    {:beer_style, 3, 'Belgian Gold Ale', {:wiki, 'http://en.wikipedia.org/wiki/Belgian_ale#Blonde_or_golden_ale'}},

    {:beer_style, 6, 'Tripel', {:catgeory, "Ale"}},
    {:beer_style, 6, 'Tripel', {:sub_category, "Belgian Ale"}},
    {:beer_style, 6, 'Tripel', {:original_gravity, 1.070, 1.100}},
    {:beer_style, 6, 'Tripel', {:final_gravity, 1.016, 1.024}},
    {:beer_style, 6, 'Tripel', {:abv, 7.0, 10.0}},
    {:beer_style, 6, 'Tripel', {:ibu, 20, 30}},
    {:beer_style, 6, 'Tripel', {:srm, 4, 7}},
    {:beer_style, 6, 'Tripel', {:wiki, 'http://en.wikipedia.org/wiki/Trippel'}},

    {:beer_style, 9, 'Saison', {:catgeory, "Ale"}},
    {:beer_style, 9, 'Saison', {:sub_category, "Belgian Ale"}},
    {:beer_style, 9, 'Saison', {:original_gravity, 1.052, 1.080}},
    {:beer_style, 9, 'Saison', {:final_gravity, 1.010, 1.015}},
    {:beer_style, 9, 'Saison', {:abv, 4.5, 8.1}},
    {:beer_style, 9, 'Saison', {:ibu, 25, 40}},
    {:beer_style, 9, 'Saison', {:srm, 4, 10}},
    {:beer_style, 9, 'Saison', {:wiki, 'http://en.wikipedia.org/wiki/Saison'}},

    {:beer_style, 16, 'Belgian Pale Ale', {:catgeory, "Ale"}},
    {:beer_style, 16, 'Belgian Pale Ale', {:sub_category, "Belgian Ale"}},
    {:beer_style, 16, 'Belgian Pale Ale', {:original_gravity, 1.040, 1.055}},
    {:beer_style, 16, 'Belgian Pale Ale', {:final_gravity, 1.008, 1.013}},
    {:beer_style, 16, 'Belgian Pale Ale', {:abv, 3.9, 5.6}},
    {:beer_style, 16, 'Belgian Pale Ale', {:ibu, 20, 35}},
    {:beer_style, 16, 'Belgian Pale Ale', {:srm, 4, 14}},
    {:beer_style, 16, 'Belgian Pale Ale', {:wiki, 'http://www.homebrewtalk.com/wiki/index.php/Belgian_Pale_Ale'}},

    {:beer_style, 29, 'Belgian Dark Ale', {:catgeory, "Ale"}},
    {:beer_style, 29, 'Belgian Dark Ale', {:sub_category, "Belgian Ale"}},
    {:beer_style, 29, 'Belgian Dark Ale', {:original_gravity, 1.065, 1.098}},
    {:beer_style, 29, 'Belgian Dark Ale', {:final_gravity, 1.014, 1.024}},
    {:beer_style, 29, 'Belgian Dark Ale', {:abv, 7.0, 12.0}},
    {:beer_style, 29, 'Belgian Dark Ale', {:ibu, 25, 40}},
    {:beer_style, 29, 'Belgian Dark Ale', {:srm, 7, 20}},
    {:beer_style, 29, 'Belgian Dark Ale', {:wiki, 'http://en.wikipedia.org/wiki/Belgian_Strong_Dark_Ale'}},

    {:beer_style, 43, 'Dubbel', {:catgeory, "Ale"}},
    {:beer_style, 43, 'Dubbel', {:sub_category, "Belgian Ale"}},
    {:beer_style, 43, 'Dubbel', {:original_gravity, 1.065, 1.085}},
    {:beer_style, 43, 'Dubbel', {:final_gravity, 1.012, 1.018}},
    {:beer_style, 43, 'Dubbel', {:abv, 3.2, 8.0}},
    {:beer_style, 43, 'Dubbel', {:ibu, 20, 25}},
    {:beer_style, 43, 'Dubbel', {:srm, 10, 20}},
    {:beer_style, 43, 'Dubbel', {:wiki, 'http://en.wikipedia.org/wiki/Dubbel'}},

    {:beer_style, 10, 'Pale Ale', {:catgeory, "Ale"}},
    {:beer_style, 10, 'Pale Ale', {:sub_category, "Pale Ale"}},
    {:beer_style, 10, 'Pale Ale', {:original_gravity, 1.043, 1.056}},
    {:beer_style, 10, 'Pale Ale', {:final_gravity, 1.008, 1.016}},
    {:beer_style, 10, 'Pale Ale', {:abv, 4.5, 5.5}},
    {:beer_style, 10, 'Pale Ale', {:ibu, 20, 40}},
    {:beer_style, 10, 'Pale Ale', {:srm, 4, 11}},
    {:beer_style, 10, 'Pale Ale', {:wiki, 'http://en.wikipedia.org/wiki/Pale_ale'}},

    {:beer_style, 17, 'American Pale Ale', {:catgeory, "Ale"}},
    {:beer_style, 17, 'American Pale Ale', {:sub_category, "Pale Ale"}},
    {:beer_style, 17, 'American Pale Ale', {:original_gravity, 1.045, 1.056}},
    {:beer_style, 17, 'American Pale Ale', {:final_gravity, 1.010, 1.015}},
    {:beer_style, 17, 'American Pale Ale', {:abv, 4.5, 5.7}},
    {:beer_style, 17, 'American Pale Ale', {:ibu, 20, 40}},
    {:beer_style, 17, 'American Pale Ale', {:srm, 4, 11}},
    {:beer_style, 17, 'American Pale Ale', {:wiki, 'http://en.wikipedia.org/wiki/American_Pale_Ale'}},

    {:beer_style, 30, 'India Pale Ale', {:catgeory, "Ale"}},
    {:beer_style, 30, 'India Pale Ale', {:sub_category, "Pale Ale"}},
    {:beer_style, 30, 'India Pale Ale', {:original_gravity, 1.050, 1.075}},
    {:beer_style, 30, 'India Pale Ale', {:final_gravity, 1.012, 1.018}},
    {:beer_style, 30, 'India Pale Ale', {:abv, 5.1, 7.6}},
    {:beer_style, 30, 'India Pale Ale', {:ibu, 40, 60}},
    {:beer_style, 30, 'India Pale Ale', {:srm, 8, 14}},
    {:beer_style, 30, 'India Pale Ale', {:wiki, 'http://en.wikipedia.org/wiki/India_Pale_Ale'}},

    {:beer_style, 44, 'American Amber Ale', {:catgeory, "Ale"}},
    {:beer_style, 44, 'American Amber Ale', {:sub_category, "Pale Ale"}},
    {:beer_style, 44, 'American Amber Ale', {:original_gravity, 1.043, 1.056}},
    {:beer_style, 44, 'American Amber Ale', {:final_gravity, 1.008, 1.016}},
    {:beer_style, 44, 'American Amber Ale', {:abv, 4.5, 5.7}},
    {:beer_style, 44, 'American Amber Ale', {:ibu, 20, 40}},
    {:beer_style, 44, 'American Amber Ale', {:srm, 11, 18}},
    {:beer_style, 44, 'American Amber Ale', {:wiki, 'http://en.wikipedia.org/wiki/Amber_lager'}},

    {:beer_style, 18, 'Ordinary Bitter', {:catgeory, "Ale"}},
    {:beer_style, 18, 'Ordinary Bitter', {:sub_category, "English Bitter"}},
    {:beer_style, 18, 'Ordinary Bitter', {:original_gravity, 1.030, 1.038}},
    {:beer_style, 18, 'Ordinary Bitter', {:final_gravity, 1.006, 1.012}},
    {:beer_style, 18, 'Ordinary Bitter', {:abv, 3.0, 3.8}},
    {:beer_style, 18, 'Ordinary Bitter', {:ibu, 20, 35}},
    {:beer_style, 18, 'Ordinary Bitter', {:srm, 6, 12}},
    {:beer_style, 18, 'Ordinary Bitter', {:wiki, 'http://en.wikipedia.org/wiki/Ordinary_bitter'}},

    {:beer_style, 31, 'Special Bitter', {:catgeory, "Ale"}},
    {:beer_style, 31, 'Special Bitter', {:sub_category, "English Bitter"}},
    {:beer_style, 31, 'Special Bitter', {:original_gravity, 1.039, 1.045}},
    {:beer_style, 31, 'Special Bitter', {:final_gravity, 1.006, 1.014}},
    {:beer_style, 31, 'Special Bitter', {:abv, 3.7, 4.8}},
    {:beer_style, 31, 'Special Bitter', {:ibu, 25, 40}},
    {:beer_style, 31, 'Special Bitter', {:srm, 12, 14}},
    {:beer_style, 31, 'Special Bitter', {:wiki, 'http://en.wikipedia.org/wiki/Bitter_(beer)'}},

    {:beer_style, 45, 'Extra Special Bitter', {:catgeory, "Ale"}},
    {:beer_style, 45, 'Extra Special Bitter', {:sub_category, "English Bitter"}},
    {:beer_style, 45, 'Extra Special Bitter', {:original_gravity, 1.046, 1.065}},
    {:beer_style, 45, 'Extra Special Bitter', {:final_gravity, 1.010, 1.018}},
    {:beer_style, 45, 'Extra Special Bitter', {:abv, 3.7, 4.8}},
    {:beer_style, 45, 'Extra Special Bitter', {:ibu, 30, 45}},
    {:beer_style, 45, 'Extra Special Bitter', {:srm, 12, 14}},
    {:beer_style, 45, 'Extra Special Bitter', {:wiki, 'http://en.wikipedia.org/wiki/Bitter_(beer)'}},

    {:beer_style, 19, 'Scottish Light 60/-', {:catgeory, "Ale"}},
    {:beer_style, 19, 'Scottish Light 60/-', {:sub_category, "Scottish Ale"}},
    {:beer_style, 19, 'Scottish Light 60/-', {:original_gravity, 1.030, 1.035}},
    {:beer_style, 19, 'Scottish Light 60/-', {:final_gravity, 1.006, 1.012}},
    {:beer_style, 19, 'Scottish Light 60/-', {:abv, 2.8, 4.0}},
    {:beer_style, 19, 'Scottish Light 60/-', {:ibu, 9, 20}},
    {:beer_style, 19, 'Scottish Light 60/-', {:srm, 8, 17}},
    {:beer_style, 19, 'Scottish Light 60/-', {:wiki, 'http://en.wikipedia.org/wiki/Scottish_beer'}},

    {:beer_style, 32, 'Scottish Heavy 70/-', {:catgeory, "Ale"}},
    {:beer_style, 32, 'Scottish Heavy 70/-', {:sub_category, "Scottish Ale"}},
    {:beer_style, 32, 'Scottish Heavy 70/-', {:original_gravity, 1.035, 1.040}},
    {:beer_style, 32, 'Scottish Heavy 70/-', {:final_gravity, 1.010, 1.014}},
    {:beer_style, 32, 'Scottish Heavy 70/-', {:abv, 3.5, 4.1}},
    {:beer_style, 32, 'Scottish Heavy 70/-', {:ibu, 12, 25}},
    {:beer_style, 32, 'Scottish Heavy 70/-', {:srm, 10, 19}},
    {:beer_style, 32, 'Scottish Heavy 70/-', {:wiki, 'http://en.wikipedia.org/wiki/Scottish_beer'}},

    {:beer_style, 46, 'Scottish Export 80/-', {:catgeory, "Ale"}},
    {:beer_style, 46, 'Scottish Export 80/-', {:sub_category, "Scottish Ale"}},
    {:beer_style, 46, 'Scottish Export 80/-', {:original_gravity, 1.040, 1.050}},
    {:beer_style, 46, 'Scottish Export 80/-', {:final_gravity, 1.010, 1.018}},
    {:beer_style, 46, 'Scottish Export 80/-', {:abv, 4.0, 4.9}},
    {:beer_style, 46, 'Scottish Export 80/-', {:ibu, 15, 36}},
    {:beer_style, 46, 'Scottish Export 80/-', {:srm, 10, 19}},
    {:beer_style, 46, 'Scottish Export 80/-', {:wiki, 'http://en.wikipedia.org/wiki/Scottish_beer'}},

    {:beer_style, 20, 'English Mild', {:catgeory, "Ale"}},
    {:beer_style, 20, 'English Mild', {:sub_category, "Brown Ale"}},
    {:beer_style, 20, 'English Mild', {:original_gravity, 1.030, 1.038}},
    {:beer_style, 20, 'English Mild', {:final_gravity, 1.004, 1.012}},
    {:beer_style, 20, 'English Mild', {:abv, 2.5, 4.1}},
    {:beer_style, 20, 'English Mild', {:ibu, 10, 24}},
    {:beer_style, 20, 'English Mild', {:srm, 10, 25}},
    {:beer_style, 20, 'English Mild', {:wiki, 'http://en.wikipedia.org/wiki/Mild_ale'}},

    {:beer_style, 33, 'American Brown', {:catgeory, "Ale"}},
    {:beer_style, 33, 'American Brown', {:sub_category, "Brown Ale"}},
    {:beer_style, 33, 'American Brown', {:original_gravity, 1.040, 1.055}},
    {:beer_style, 33, 'American Brown', {:final_gravity, 1.010, 1.018}},
    {:beer_style, 33, 'American Brown', {:abv, 4.2, 6.0}},
    {:beer_style, 33, 'American Brown', {:ibu, 25, 60}},
    {:beer_style, 33, 'American Brown', {:srm, 15, 22}},
    {:beer_style, 33, 'American Brown', {:wiki, 'http://beeradvocate.com/beer/style/73'}},

    {:beer_style, 47, 'English Brown', {:catgeory, "Ale"}},
    {:beer_style, 47, 'English Brown', {:sub_category, "Brown Ale"}},
    {:beer_style, 47, 'English Brown', {:original_gravity, 1.040, 1.050}},
    {:beer_style, 47, 'English Brown', {:final_gravity, 1.008, 1.014}},
    {:beer_style, 47, 'English Brown', {:abv, 3.5, 6.0}},
    {:beer_style, 47, 'English Brown', {:ibu, 15, 25}},
    {:beer_style, 47, 'English Brown', {:srm, 15, 30}},
    {:beer_style, 47, 'English Brown', {:wiki, 'http://en.wikipedia.org/wiki/English_brown_ale'}},

    {:beer_style, 34, 'Brown Porter', {:catgeory, "Ale"}},
    {:beer_style, 34, 'Brown Porter', {:sub_category, "Porter"}},
    {:beer_style, 34, 'Brown Porter', {:original_gravity, 1.040, 1.050}},
    {:beer_style, 34, 'Brown Porter', {:final_gravity, 1.008, 1.014}},
    {:beer_style, 34, 'Brown Porter', {:abv, 3.8, 5.2}},
    {:beer_style, 34, 'Brown Porter', {:ibu, 20, 30}},
    {:beer_style, 34, 'Brown Porter', {:srm, 20, 30}},
    {:beer_style, 34, 'Brown Porter', {:wiki, 'http://en.wikipedia.org/wiki/Porter_(beer)'}},

    {:beer_style, 48, 'Robust Porter', {:catgeory, "Ale"}},
    {:beer_style, 48, 'Robust Porter', {:sub_category, "Porter"}},
    {:beer_style, 48, 'Robust Porter', {:original_gravity, 1.050, 1.065}},
    {:beer_style, 48, 'Robust Porter', {:final_gravity, 1.012, 1.016}},
    {:beer_style, 48, 'Robust Porter', {:abv, 4.8, 6.0}},
    {:beer_style, 48, 'Robust Porter', {:ibu, 25, 45}},
    {:beer_style, 48, 'Robust Porter', {:srm, 30, 40}},
    {:beer_style, 48, 'Robust Porter', {:wiki, 'http://en.wikipedia.org/wiki/Porter_(beer)'}},

    # Beer Dry Stout has SRM 40+! Defaulting Range 40-100!
    {:beer_style, 21, 'Dry Stout', {:catgeory, "Ale"}},
    {:beer_style, 21, 'Dry Stout', {:sub_category, "Stout"}},
    {:beer_style, 21, 'Dry Stout', {:original_gravity, 1.035, 1.050}},
    {:beer_style, 21, 'Dry Stout', {:final_gravity, 1.008, 1.014}},
    {:beer_style, 21, 'Dry Stout', {:abv, 3.2, 5.5}},
    {:beer_style, 21, 'Dry Stout', {:ibu, 30, 50}},
    {:beer_style, 21, 'Dry Stout', {:srm, 40, 100}},
    {:beer_style, 21, 'Dry Stout', {:wiki, 'http://en.wikipedia.org/wiki/Dry_stout'}},

    # Beer Sweet Stout has SRM 40+! Defaulting Range 40-100!
    {:beer_style, 35, 'Sweet Stout', {:catgeory, "Ale"}},
    {:beer_style, 35, 'Sweet Stout', {:sub_category, "Stout"}},
    {:beer_style, 35, 'Sweet Stout', {:original_gravity, 1.035, 1.066}},
    {:beer_style, 35, 'Sweet Stout', {:final_gravity, 1.010, 1.022}},
    {:beer_style, 35, 'Sweet Stout', {:abv, 3.2, 6.4}},
    {:beer_style, 35, 'Sweet Stout', {:ibu, 20, 40}},
    {:beer_style, 35, 'Sweet Stout', {:srm, 40, 100}},
    {:beer_style, 35, 'Sweet Stout', {:wiki, 'http://en.wikipedia.org/wiki/Sweet_stout'}},

    # Beer Oatmeal Stout has SRM 40+! Defaulting Range 40-100!
    {:beer_style, 49, 'Oatmeal Stout', {:catgeory, "Ale"}},
    {:beer_style, 49, 'Oatmeal Stout', {:sub_category, "Stout"}},
    {:beer_style, 49, 'Oatmeal Stout', {:original_gravity, 1.035, 1.060}},
    {:beer_style, 49, 'Oatmeal Stout', {:final_gravity, 1.008, 1.021}},
    {:beer_style, 49, 'Oatmeal Stout', {:abv, 3.3, 6.1}},
    {:beer_style, 49, 'Oatmeal Stout', {:ibu, 20, 50}},
    {:beer_style, 49, 'Oatmeal Stout', {:srm, 40, 100}},
    {:beer_style, 49, 'Oatmeal Stout', {:wiki, 'http://en.wikipedia.org/wiki/Oatmeal_stout'}},

    # Beer Foreign Extra Stout has SRM 40+! Defaulting Range 40-100!
    {:beer_style, 22, 'Foreign Extra Stout', {:catgeory, "Ale"}},
    {:beer_style, 22, 'Foreign Extra Stout', {:sub_category, "Stout"}},
    {:beer_style, 22, 'Foreign Extra Stout', {:original_gravity, 1.050, 1.075}},
    {:beer_style, 22, 'Foreign Extra Stout', {:final_gravity, 1.010, 1.017}},
    {:beer_style, 22, 'Foreign Extra Stout', {:abv, 5.0, 7.5}},
    {:beer_style, 22, 'Foreign Extra Stout', {:ibu, 35, 70}},
    {:beer_style, 22, 'Foreign Extra Stout', {:srm, 40, 100}},
    {:beer_style, 22, 'Foreign Extra Stout', {:wiki, 'http://www.brewwiki.com/index.php/Foreign_Extra_Stout'}},

    # Beer Imperial Stout has SRM 40+! Defaulting Range 40-100!
    {:beer_style, 36, 'Imperial Stout', {:catgeory, "Ale"}},
    {:beer_style, 36, 'Imperial Stout', {:sub_category, "Stout"}},
    {:beer_style, 36, 'Imperial Stout', {:original_gravity, 1.075, 1.090}},
    {:beer_style, 36, 'Imperial Stout', {:final_gravity, 1.020, 1.030}},
    {:beer_style, 36, 'Imperial Stout', {:abv, 7.8, 9.0}},
    {:beer_style, 36, 'Imperial Stout', {:ibu, 50, 80}},
    {:beer_style, 36, 'Imperial Stout', {:srm, 40, 100}},
    {:beer_style, 36, 'Imperial Stout', {:wiki, 'http://en.wikipedia.org/wiki/Imperial_stout'}},

    # Beer Russian Imperial has SRM 40+! Defaulting Range 40-100!
    {:beer_style, 50, 'Russian Imperial', {:catgeory, "Ale"}},
    {:beer_style, 50, 'Russian Imperial', {:sub_category, "Stout"}},
    {:beer_style, 50, 'Russian Imperial', {:original_gravity, 1.075, 1.100}},
    {:beer_style, 50, 'Russian Imperial', {:final_gravity, 1.018, 1.030}},
    {:beer_style, 50, 'Russian Imperial', {:abv, 8.0, 12.0}},
    {:beer_style, 50, 'Russian Imperial', {:ibu, 50, 90}},
    {:beer_style, 50, 'Russian Imperial', {:srm, 40, 100}},
    {:beer_style, 50, 'Russian Imperial', {:wiki, 'http://en.wikipedia.org/wiki/Russian_Imperial_Stout'}},

    {:beer_style, 23, 'German Pilsner', {:catgeory, "Lager"}},
    {:beer_style, 23, 'German Pilsner', {:sub_category, "Pilsner"}},
    {:beer_style, 23, 'German Pilsner', {:original_gravity, 1.044, 1.050}},
    {:beer_style, 23, 'German Pilsner', {:final_gravity, 1.006, 1.012}},
    {:beer_style, 23, 'German Pilsner', {:abv, 4.6, 5.4}},
    {:beer_style, 23, 'German Pilsner', {:ibu, 25, 45}},
    {:beer_style, 23, 'German Pilsner', {:srm, 2, 4}},
    {:beer_style, 23, 'German Pilsner', {:wiki, 'http://beeradvocate.com/articles/216'}},

    {:beer_style, 37, 'Bohemian Pilsner', {:catgeory, "Lager"}},
    {:beer_style, 37, 'Bohemian Pilsner', {:sub_category, "Pilsner"}},
    {:beer_style, 37, 'Bohemian Pilsner', {:original_gravity, 1.044, 1.056}},
    {:beer_style, 37, 'Bohemian Pilsner', {:final_gravity, 1.014, 1.020}},
    {:beer_style, 37, 'Bohemian Pilsner', {:abv, 4.1, 5.1}},
    {:beer_style, 37, 'Bohemian Pilsner', {:ibu, 35, 45}},
    {:beer_style, 37, 'Bohemian Pilsner', {:srm, 3, 5}},
    {:beer_style, 37, 'Bohemian Pilsner', {:wiki, 'http://en.wikipedia.org/wiki/Pilsner'}},

    {:beer_style, 51, 'American Pilsner', {:catgeory, "Lager"}},
    {:beer_style, 51, 'American Pilsner', {:sub_category, "Pilsner"}},
    {:beer_style, 51, 'American Pilsner', {:original_gravity, 1.045, 1.060}},
    {:beer_style, 51, 'American Pilsner', {:final_gravity, 1.012, 1.018}},
    {:beer_style, 51, 'American Pilsner', {:abv, 5.0, 6.0}},
    {:beer_style, 51, 'American Pilsner', {:ibu, 20, 40}},
    {:beer_style, 51, 'American Pilsner', {:srm, 3, 6}},
    {:beer_style, 51, 'American Pilsner', {:wiki, 'http://www.bjcp.org/2008styles/style02.php#1c'}},

    {:beer_style, 24, 'American Standard', {:catgeory, "Lager"}},
    {:beer_style, 24, 'American Standard', {:sub_category, "American Lager"}},
    {:beer_style, 24, 'American Standard', {:original_gravity, 1.040, 1.046}},
    {:beer_style, 24, 'American Standard', {:final_gravity, 1.006, 1.010}},
    {:beer_style, 24, 'American Standard', {:abv, 4.1, 4.8}},
    {:beer_style, 24, 'American Standard', {:ibu, 5, 17}},
    {:beer_style, 24, 'American Standard', {:srm, 2, 6}},
    {:beer_style, 24, 'American Standard', {:wiki, 'http://www.pintley.com/browse/style/Standard-American-Lager/4?p=1&s=n&d=a'}},

    {:beer_style, 38, 'American Premium', {:catgeory, "Lager"}},
    {:beer_style, 38, 'American Premium', {:sub_category, "American Lager"}},
    {:beer_style, 38, 'American Premium', {:original_gravity, 1.046, 1.050}},
    {:beer_style, 38, 'American Premium', {:final_gravity, 1.010, 1.014}},
    {:beer_style, 38, 'American Premium', {:abv, 4.6, 5.1}},
    {:beer_style, 38, 'American Premium', {:ibu, 13, 23}},
    {:beer_style, 38, 'American Premium', {:srm, 2, 8}},
    {:beer_style, 38, 'American Premium', {:wiki, 'http://greatbrewers.com/style/american-style-premium-lager'}},

    {:beer_style, 52, 'American Dark', {:catgeory, "Lager"}},
    {:beer_style, 52, 'American Dark', {:sub_category, "American Lager"}},
    {:beer_style, 52, 'American Dark', {:original_gravity, 1.040, 1.050}},
    {:beer_style, 52, 'American Dark', {:final_gravity, 1.008, 1.012}},
    {:beer_style, 52, 'American Dark', {:abv, 4.1, 5.6}},
    {:beer_style, 52, 'American Dark', {:ibu, 14, 20}},
    {:beer_style, 52, 'American Dark', {:srm, 10, 20}},
    {:beer_style, 52, 'American Dark', {:wiki, 'http://www.brewwiki.com/index.php/Dark_American_Lager'}},

    {:beer_style, 12, 'Munich Helles', {:catgeory, "Lager"}},
    {:beer_style, 12, 'Munich Helles', {:sub_category, "European Lager"}},
    {:beer_style, 12, 'Munich Helles', {:original_gravity, 1.044, 1.050}},
    {:beer_style, 12, 'Munich Helles', {:final_gravity, 1.008, 1.012}},
    {:beer_style, 12, 'Munich Helles', {:abv, 4.5, 5.6}},
    {:beer_style, 12, 'Munich Helles', {:ibu, 18, 25}},
    {:beer_style, 12, 'Munich Helles', {:srm, 3, 5}},
    {:beer_style, 12, 'Munich Helles', {:wiki, 'http://beeradvocate.com/beer/style/21'}},

    {:beer_style, 25, 'Dortmunder', {:catgeory, "Lager"}},
    {:beer_style, 25, 'Dortmunder', {:sub_category, "European Lager"}},
    {:beer_style, 25, 'Dortmunder', {:original_gravity, 1.048, 1.056}},
    {:beer_style, 25, 'Dortmunder', {:final_gravity, 1.010, 1.014}},
    {:beer_style, 25, 'Dortmunder', {:abv, 5.1, 6.1}},
    {:beer_style, 25, 'Dortmunder', {:ibu, 23, 29}},
    {:beer_style, 25, 'Dortmunder', {:srm, 4, 6}},
    {:beer_style, 25, 'Dortmunder', {:wiki, 'http://en.wikipedia.org/wiki/Dortmunder_(beer)'}},

    {:beer_style, 39, 'Munich Dunkel', {:catgeory, "Lager"}},
    {:beer_style, 39, 'Munich Dunkel', {:sub_category, "European Lager"}},
    {:beer_style, 39, 'Munich Dunkel', {:original_gravity, 1.052, 1.056}},
    {:beer_style, 39, 'Munich Dunkel', {:final_gravity, 1.010, 1.014}},
    {:beer_style, 39, 'Munich Dunkel', {:abv, 4.8, 5.4}},
    {:beer_style, 39, 'Munich Dunkel', {:ibu, 16, 25}},
    {:beer_style, 39, 'Munich Dunkel', {:srm, 17, 23}},
    {:beer_style, 39, 'Munich Dunkel', {:wiki, 'http://en.wikipedia.org/wiki/Munich_dunkel_lager'}},

    # Beer Schwarzbier converted 40+ to 100
    {:beer_style, 53, 'Schwarzbier', {:catgeory, "Lager"}},
    {:beer_style, 53, 'Schwarzbier', {:sub_category, "European Lager"}},
    {:beer_style, 53, 'Schwarzbier', {:original_gravity, 1.044, 1.052}},
    {:beer_style, 53, 'Schwarzbier', {:final_gravity, 1.012, 1.016}},
    {:beer_style, 53, 'Schwarzbier', {:abv, 3.8, 5.0}},
    {:beer_style, 53, 'Schwarzbier', {:ibu, 22, 30}},
    {:beer_style, 53, 'Schwarzbier', {:srm, 25, 100}},
    {:beer_style, 53, 'Schwarzbier', {:wiki, 'http://en.wikipedia.org/wiki/Schwarzbier'}},

    {:beer_style, 13, 'Helles Bock', {:catgeory, "Lager"}},
    {:beer_style, 13, 'Helles Bock', {:sub_category, "Bock"}},
    {:beer_style, 13, 'Helles Bock', {:original_gravity, 1.066, 1.074}},
    {:beer_style, 13, 'Helles Bock', {:final_gravity, 1.011, 1.020}},
    {:beer_style, 13, 'Helles Bock', {:abv, 6.0, 7.5}},
    {:beer_style, 13, 'Helles Bock', {:ibu, 20, 35}},
    {:beer_style, 13, 'Helles Bock', {:srm, 4, 10}},
    {:beer_style, 13, 'Helles Bock', {:wiki, 'http://en.wikipedia.org/wiki/Bock#Maibock_or_helles_bock'}},

    {:beer_style, 26, 'Doppelbock', {:catgeory, "Lager"}},
    {:beer_style, 26, 'Doppelbock', {:sub_category, "Bock"}},
    {:beer_style, 26, 'Doppelbock', {:original_gravity, 1.074, 1.080}},
    {:beer_style, 26, 'Doppelbock', {:final_gravity, 1.020, 1.028}},
    {:beer_style, 26, 'Doppelbock', {:abv, 6.6, 7.9}},
    {:beer_style, 26, 'Doppelbock', {:ibu, 20, 30}},
    {:beer_style, 26, 'Doppelbock', {:srm, 12, 30}},
    {:beer_style, 26, 'Doppelbock', {:wiki, 'http://en.wikipedia.org/wiki/Bock#Doppelbock'}},

    {:beer_style, 40, 'Traditional Bock', {:catgeory, "Lager"}},
    {:beer_style, 40, 'Traditional Bock', {:sub_category, "Bock"}},
    {:beer_style, 40, 'Traditional Bock', {:original_gravity, 1.066, 1.074}},
    {:beer_style, 40, 'Traditional Bock', {:final_gravity, 1.018, 1.024}},
    {:beer_style, 40, 'Traditional Bock', {:abv, 6.4, 7.6}},
    {:beer_style, 40, 'Traditional Bock', {:ibu, 20, 30}},
    {:beer_style, 40, 'Traditional Bock', {:srm, 15, 30}},
    {:beer_style, 40, 'Traditional Bock', {:wiki, 'http://en.wikipedia.org/wiki/Bock#Traditional_bock'}},

    # Beer Eisbock converted 40+ to 100
    {:beer_style, 54, 'Eisbock', {:catgeory, "Lager"}},
    {:beer_style, 54, 'Eisbock', {:sub_category, "Bock"}},
    {:beer_style, 54, 'Eisbock', {:original_gravity, 1.090, 1.116}},
    {:beer_style, 54, 'Eisbock', {:final_gravity, 1.023, 1.035}},
    {:beer_style, 54, 'Eisbock', {:abv, 8.7, 14.4}},
    {:beer_style, 54, 'Eisbock', {:ibu, 25, 50}},
    {:beer_style, 54, 'Eisbock', {:srm, 18, 100}},
    {:beer_style, 54, 'Eisbock', {:wiki, 'http://en.wikipedia.org/wiki/Bock#Eisbock'}},

    {:beer_style, 61, 'Altbier', {:catgeory, "Other"}},
    {:beer_style, 61, 'Altbier', {:sub_category, "Other"}},
    {:beer_style, 61, 'Altbier', {:original_gravity, 1.044, 1.048}},
    {:beer_style, 61, 'Altbier', {:final_gravity, 1.008, 1.014}},
    {:beer_style, 61, 'Altbier', {:abv, 4.6, 5.1}},
    {:beer_style, 61, 'Altbier', {:ibu, 25, 48}},
    {:beer_style, 61, 'Altbier', {:srm, 11, 19}},
    {:beer_style, 61, 'Altbier', {:wiki, 'http://en.wikipedia.org/wiki/Altbier'}},

    {:beer_style, 56, 'Biére de Garde', {:catgeory, "Other"}},
    {:beer_style, 56, 'Biére de Garde', {:sub_category, "Other"}},
    {:beer_style, 56, 'Biére de Garde', {:original_gravity, 1.060, 1.080}},
    {:beer_style, 56, 'Biére de Garde', {:final_gravity, 1.012, 1.016}},
    {:beer_style, 56, 'Biére de Garde', {:abv, 4.5, 8.0}},
    {:beer_style, 56, 'Biére de Garde', {:ibu, 20, 30}},
    {:beer_style, 56, 'Biére de Garde', {:srm, 5, 12}},
    {:beer_style, 56, 'Biére de Garde', {:wiki, 'http://en.wikipedia.org/wiki/Bi%C3%A8re_de_Garde'}},

    {:beer_style, 57, 'Oktoberfest', {:catgeory, "Other"}},
    {:beer_style, 57, 'Oktoberfest', {:sub_category, "Other"}},
    {:beer_style, 57, 'Oktoberfest', {:original_gravity, 1.050, 1.056}},
    {:beer_style, 57, 'Oktoberfest', {:final_gravity, 1.012, 1.016}},
    {:beer_style, 57, 'Oktoberfest', {:abv, 5.1, 6.5}},
    {:beer_style, 57, 'Oktoberfest', {:ibu, 18, 30}},
    {:beer_style, 57, 'Oktoberfest', {:srm, 7, 12}},
    {:beer_style, 57, 'Oktoberfest', {:wiki, 'http://en.wikipedia.org/wiki/Oktoberfest_Beer'}},

    {:beer_style, 62, 'Vienna', {:catgeory, "Other"}},
    {:beer_style, 62, 'Vienna', {:sub_category, "Other"}},
    {:beer_style, 62, 'Vienna', {:original_gravity, 1.048, 1.056}},
    {:beer_style, 62, 'Vienna', {:final_gravity, 1.010, 1.014}},
    {:beer_style, 62, 'Vienna', {:abv, 4.6, 5.5}},
    {:beer_style, 62, 'Vienna', {:ibu, 20, 28}},
    {:beer_style, 62, 'Vienna', {:srm, 8, 14}},
    {:beer_style, 62, 'Vienna', {:wiki, 'http://en.wikipedia.org/wiki/Vienna_lager'}},

    {:beer_style, 58, 'Cream Ale', {:catgeory, "Other"}},
    {:beer_style, 58, 'Cream Ale', {:sub_category, "Other"}},
    {:beer_style, 58, 'Cream Ale', {:original_gravity, 1.044, 1.055}},
    {:beer_style, 58, 'Cream Ale', {:final_gravity, 1.007, 1.010}},
    {:beer_style, 58, 'Cream Ale', {:abv, 4.5, 6.0}},
    {:beer_style, 58, 'Cream Ale', {:ibu, 10, 35}},
    {:beer_style, 58, 'Cream Ale', {:srm, 8, 14}},
    {:beer_style, 58, 'Cream Ale', {:wiki, 'http://en.wikipedia.org/wiki/Cream_ale'}},

    {:beer_style, 63, 'Steam Beer', {:catgeory, "Other"}},
    {:beer_style, 63, 'Steam Beer', {:sub_category, "Other"}},
    {:beer_style, 63, 'Steam Beer', {:original_gravity, 1.040, 1.055}},
    {:beer_style, 63, 'Steam Beer', {:final_gravity, 1.012, 1.018}},
    {:beer_style, 63, 'Steam Beer', {:abv, 3.6, 5.0}},
    {:beer_style, 63, 'Steam Beer', {:ibu, 35, 45}},
    {:beer_style, 63, 'Steam Beer', {:srm, 8, 17}},
    {:beer_style, 63, 'Steam Beer', {:wiki, 'http://en.wikipedia.org/wiki/Steam_beer'}},

    {:beer_style, 59, 'Smoked Beer', {:catgeory, "Other"}},
    {:beer_style, 59, 'Smoked Beer', {:sub_category, "Other"}},
    {:beer_style, 59, 'Smoked Beer', {:original_gravity, 1.050, 1.055}},
    {:beer_style, 59, 'Smoked Beer', {:final_gravity, 1.012, 1.016}},
    {:beer_style, 59, 'Smoked Beer', {:abv, 5.0, 5.5}},
    {:beer_style, 59, 'Smoked Beer', {:ibu, 20, 30}},
    {:beer_style, 59, 'Smoked Beer', {:srm, 12, 17}},
    {:beer_style, 59, 'Smoked Beer', {:wiki, 'http://en.wikipedia.org/wiki/Smoked_beer'}},

    {:beer_style, 64, 'Barleywine', {:catgeory, "Other"}},
    {:beer_style, 64, 'Barleywine', {:sub_category, "Other"}},
    {:beer_style, 64, 'Barleywine', {:original_gravity, 1.085, 1.120}},
    {:beer_style, 64, 'Barleywine', {:final_gravity, 1.024, 1.032}},
    {:beer_style, 64, 'Barleywine', {:abv, 8.4, 12.2}},
    {:beer_style, 64, 'Barleywine', {:ibu, 50, 100}},
    {:beer_style, 64, 'Barleywine', {:srm, 14, 22}},
    {:beer_style, 64, 'Barleywine', {:wiki, 'http://en.wikipedia.org/wiki/Barley_wine'}},

    {:beer_style, 60, 'English Old Ale', {:catgeory, "Other"}},
    {:beer_style, 60, 'English Old Ale', {:sub_category, "Other"}},
    {:beer_style, 60, 'English Old Ale', {:original_gravity, 1.060, 1.090}},
    {:beer_style, 60, 'English Old Ale', {:final_gravity, 1.015, 1.022}},
    {:beer_style, 60, 'English Old Ale', {:abv, 6.1, 8.5}},
    {:beer_style, 60, 'English Old Ale', {:ibu, 30, 40}},
    {:beer_style, 60, 'English Old Ale', {:srm, 12, 16}},
    {:beer_style, 60, 'English Old Ale', {:wiki, 'http://en.wikipedia.org/wiki/Old_ale'}},

    # Beer Strong Scotch Ale converted 40+ to 100
    {:beer_style, 65, 'Strong Scotch Ale', {:catgeory, "Other"}},
    {:beer_style, 65, 'Strong Scotch Ale', {:sub_category, "Other"}},
    {:beer_style, 65, 'Strong Scotch Ale', {:original_gravity, 1.072, 1.085}},
    {:beer_style, 65, 'Strong Scotch Ale', {:final_gravity, 1.016, 1.028}},
    {:beer_style, 65, 'Strong Scotch Ale', {:abv, 6.0, 9.0}},
    {:beer_style, 65, 'Strong Scotch Ale', {:ibu, 20, 40}},
    {:beer_style, 65, 'Strong Scotch Ale', {:srm, 10, 100}},
    {:beer_style, 65, 'Strong Scotch Ale', {:wiki, 'http://en.wikipedia.org/wiki/Scotch_Ale'}}
  ]

  def add_to(engine) do
    :seresye.assert(engine, @facts)
  end

end