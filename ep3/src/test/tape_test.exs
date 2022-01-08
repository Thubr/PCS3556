defmodule TapeTest do
  use ExUnit.Case
  alias Tape
  @moduletag :capture_log
  doctest Tape

  test "module exists" do
    assert is_list(Tape.module_info())
  end

  test "is creating tape" do
    {:ok, tape} = Tape.init(["a", "b", "a", "b"])
    assert Tape.contents(tape) == [["$"], ["a", "b", "a", "b"]]
  end

  test "is reading tape" do
    {:ok, tape} = Tape.init(["$", "a"], ["b", "c"])
    assert Tape.at(tape) == "b"
  end

  test "is moving to the right" do
    {:ok, tape} = Tape.init(["$", "a"], ["b", "c", "d"])
    assert Tape.reconfig!(tape) == :ok
    assert Tape.contents(tape) == [["$", "a", "b"], ["c", "d"]]
  end
end
