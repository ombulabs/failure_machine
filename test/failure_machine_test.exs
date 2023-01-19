defmodule FailureMachineTest do
  use ExUnit.Case
  doctest FailureMachine

  test "greets the world" do
    assert FailureMachine.hello() == :world
  end
end
