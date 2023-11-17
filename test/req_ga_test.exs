defmodule ReqGaTest do
  use ExUnit.Case
  doctest ReqGa

  test "greets the world" do
    assert ReqGa.hello() == :world
  end
end
