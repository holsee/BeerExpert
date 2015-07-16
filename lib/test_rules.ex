defmodule TestRules do
  require Logger
  
  def rule_foobar(engine, {:foo, x}, {:bar, x}) do
    #Logger.debug("Triggered: foobar for #{x}")
    :seresye_engine.assert(engine, {:foobar, x})
  end
end