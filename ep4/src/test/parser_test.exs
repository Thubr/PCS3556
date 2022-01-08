defmodule ParserTest do
  use ExUnit.Case

  alias Parser

  @moduletag :capture_log

  doctest Parser

  test "module exists" do
    assert is_list(Parser.module_info())
  end

  test "parsing is working for case 1" do
    nonterminal = ["S", "A", "B"]
    terminal = ["a", "b"]

    ruleset = [
      {["S"], ["A", "B"]},
      {["A"], ["a"]},
      {["A"], ["B", "B"]},
      {["B"], ["b"]},
      {["B"], ["A", "B"]}
    ]

    initial = "S"

    assert Parser.parse(["a", "a", "b", "b", "b"], {nonterminal, terminal, ruleset, initial}) ==
             true

    assert Parser.parse(["b", "a", "b", "b", "b"], {nonterminal, terminal, ruleset, initial}) ==
             false
  end

  test "parsing is working for case 2" do
    nonterminal = ["S", "S1"]
    terminal = ["(", ")"]

    ruleset = [
      {["S"], ["S", "S"]},
      {["S"], ["(", "S1"]},
      {["S1"], ["S", ")"]},
      {["S"], ["(", ")"]}
    ]

    initial = "S"
    grammar = Normalizer.normalize({nonterminal, terminal, ruleset, initial})
    assert Parser.parse(["(", "(", ")", "(", "(", ")", ")", ")"], grammar) == true
    assert Parser.parse(["(", "(", ")", "(", "(", ")", ")"], grammar) == false
  end
end
