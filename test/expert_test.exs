defmodule ExpertTest do
  use ExUnit.Case

  require Logger

  @engine :test_beer_engine

  test "start beer expert" do
    assert :ok = Expert.start
  end

end
