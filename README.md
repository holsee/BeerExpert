Beer Expert
===========

An expert system written in elixir (using the Erlang [seresye](https://github.com/afiniate/seresye) engine) to aid in beer classification based on known information about a given beer.

The systems knowledge is comprised of facts obtained from the [beer periodic table](http://www.periodicbeer.com/).

### Usage

Start the expert.

``` elixir
Expert.start
```

Provide the Expert with some information pertaining to the beer your which to classify

``` elixir
Expert.tell 'Boiler Room', {:abv, 2.9}

# abv_categorise => Expert thinks Boiler Room could be a English Mild as abv 2.9 is between 2.5 & 4.1
# abv_categorise => Expert thinks Boiler Room could be a Berliner Weisse as abv 2.9 is between 2.5 & 3.6
# abv_categorise => Expert thinks Boiler Room could be a Scottish Light 60/- as abv 2.9 is between 2.8 & 4.0

Expert.tell 'Boiler Room', {:ibu, 7}

# etc...
```

Ask the Expert what classifications match the beer:

``` elixir
Expert.ask 'Boiler Room'

# => 

[{:beer_match, 'Boiler Room', {:beer_style, 19, 'Scottish Light 60/-'}},
 {:beer_match, 'Boiler Room', {:beer_style, 1, 'Berliner Weisse'}},
 {:beer_match, 'Boiler Room', {:beer_style, 20, 'English Mild'}}]
```

### TODO

- Finish implementing all the rules.
- Tidy up Expert layer, maybe find a smarter way to refine the matches.
- Add ```Expert.how``` method to backtrack the decisions taken to classify beer.

### Contribute

Fork and PR... simple as that.

### License

BSD License
