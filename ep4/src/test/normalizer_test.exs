defmodule NormalizerTest do
  use ExUnit.Case
  #     @tag :pending
  test "non-terminal symbol generation" do
    Normalizer.start_grammar(["V1", "A", "B", "S"], [], "S")
    assert Normalizer.new_symbol(:non_terminal) == "V2"
    assert Normalizer.get_grammar() == {["V2", "V1", "A", "B", "S"], [], "S"}
  end

  #     @tag :pending
  test "pseudo-terminal symbol generation" do
    Normalizer.start_grammar(["T1", "A", "B", "S"], ["a"], "S")
    assert Normalizer.new_symbol(:terminal, "a") == "T2"
    assert Normalizer.get_grammar() == {["T2", "T1", "A", "B", "S"], ["a"], "S"}
  end

  test "fetching already generated pseudo-terminal" do
    Normalizer.start_grammar(["A", "B", "S"], ["a"], "S")
    terminal = Normalizer.new_symbol(:terminal, "a")
    assert Normalizer.new_symbol(:terminal, "a") == terminal
    assert Normalizer.get_grammar() == {["T1", "A", "B", "S"], ["a"], "S"}
  end

  #     @tag :pending
  test "new start symbol generation" do
    Normalizer.start_grammar(["S1", "A", "B", "S"], [], "S")
    assert Normalizer.change_initial() == "S2"
    assert Normalizer.get_grammar() == {["S2", "S1", "A", "B", "S"], [], "S2"}
  end

  test "fixing initial symbol problems" do
    Normalizer.start_grammar(["S1", "A", "S"], ["a"], "S")
    ruleset = [{["S"], ["S1"]}, {["S1"], ["A"]}, {["A"], ["S"]}, {["A"], ["a"]}]
    assert Normalizer.fix_starter(ruleset) -- ruleset == [{["S2"], ["S"]}]
    assert Normalizer.get_grammar() == {["S2", "S1", "A", "S"], ["a"], "S2"}
  end

  test "fixing one nullable production" do
    ruleset = [
      {["A"], :epsilon},
      {["S"], ["A", "B", "B", "A"]},
      {["B"], ["C", "A", "B", "A", "C", "A"]}
    ]

    rules1 = [{["S"], ["B", "B"]}, {["S"], ["A", "B", "B"]}, {["S"], ["B", "B", "A"]}]

    rules2 = [
      {["B"], ["C", "B", "C"]},
      {["B"], ["C", "B", "A", "C"]},
      {["B"], ["C", "B", "C", "A"]},
      {["B"], ["C", "A", "B", "C"]},
      {["B"], ["C", "A", "B", "A", "C"]},
      {["B"], ["C", "A", "B", "C", "A"]},
      {["B"], ["C", "B", "A", "C", "A"]}
    ]

    assert Normalizer.fix_nullable(ruleset) ==
             rules1 ++
               rules2 ++ [{["S"], ["A", "B", "B", "A"]}, {["B"], ["C", "A", "B", "A", "C", "A"]}]
  end

  test "fixing multiple nullable productions" do
    ruleset = [
      {["A"], :epsilon},
      {["B"], :epsilon},
      {["S"], ["A", "B", "A", "C"]},
      {["A"], ["a", "A"]},
      {["B"], ["b", "B"]}
    ]

    rulesA = [
      {["S"], ["B", "C"]},
      {["S"], ["A", "B", "C"]},
      {["S"], ["B", "A", "C"]},
      {["A"], ["a"]}
    ]

    rulesB = [
      {["S"], ["C"]},
      {["S"], ["A", "C"]},
      {["S"], ["A", "A", "C"]},
      {["B"], ["b"]}
    ]

    assert Normalizer.fix_nullable(ruleset) ==
             rulesB ++
               rulesA ++ [{["S"], ["A", "B", "A", "C"]}, {["A"], ["a", "A"]}, {["B"], ["b", "B"]}]
  end

  test "fixing one long rule" do
    Normalizer.start_grammar(["A", "B", "S"], ["a", "b"], "S")
    ruleset = [{["S"], ["A", "B", "C"]}, {["A"], ["a"]}, {["B"], ["b"]}]

    assert Normalizer.fix_long(ruleset) == [
             {["A"], ["a"]},
             {["B"], ["b"]},
             {["V1"], ["B", "C"]},
             {["S"], ["A", "V1"]}
           ]

    assert Normalizer.get_grammar() == {["V1", "A", "B", "S"], ["a", "b"], "S"}
  end

  test "fixing multiple long rules" do
    Normalizer.start_grammar(["A", "B", "C", "S"], ["a", "b"], "S")

    ruleset = [
      {["S"], ["A", "B", "C"]},
      {["C"], ["A", "A", "B", "B", "A"]},
      {["A"], ["a"]},
      {["B"], ["b"]}
    ]

    assert Normalizer.fix_long(ruleset) == [
             {["A"], ["a"]},
             {["B"], ["b"]},
             {["V1"], ["B", "C"]},
             {["S"], ["A", "V1"]},
             {["V4"], ["B", "A"]},
             {["V3"], ["B", "V4"]},
             {["V2"], ["A", "V3"]},
             {["C"], ["A", "V2"]}
           ]

    assert Normalizer.get_grammar() ==
             {["V4", "V3", "V2", "V1", "A", "B", "C", "S"], ["a", "b"], "S"}
  end

  test "fixing mixed terminal, non-terminal rules" do
    Normalizer.start_grammar(["A", "B", "S"], ["a", "b"], "S")
    ruleset = [{["S"], ["A", "B", "C"]}, {["A"], ["a", "A"]}]

    assert Normalizer.fix_terminal(ruleset) == [
             {["A"], ["T1", "A"]},
             {["T1"], ["a"]},
             {["S"], ["A", "B", "C"]}
           ]
  end

  test "fixing unit productions" do
    Normalizer.start_grammar(["A", "B", "C", "S"], ["a", "b"], "S")

    ruleset = [
      {["S"], ["A", "B", "C"]},
      {["A"], ["B"]},
      {["B"], ["C"]},
      {["C"], ["a"]},
      {["C"], ["b"]}
    ]

    assert Normalizer.fix_unit(ruleset) == [
             {["S"], ["A", "B", "C"]},
             {["C"], ["a"]},
             {["C"], ["b"]},
             {["B"], ["b"]},
             {["B"], ["a"]},
             {["A"], ["b"]},
             {["A"], ["a"]}
           ]
  end

  test "normalizing to chomsky form" do
    nonterminal = ["S", "A", "B"]
    terminal = ["a", "b", "c"]
    initial = "S"
    ruleset = [{["S"], ["A", "B", "a"]}, {["A"], ["a", "a", "b"]}, {["B"], ["A", "c"]}]

    assert Normalizer.normalize({nonterminal, terminal, ruleset, initial}) ==
             {["T3", "T2", "T1", "V2", "V1", "S", "A", "B"], terminal,
              [
                {["B"], ["A", "T1"]},
                {["T1"], ["c"]},
                {["V1"], ["B", "T2"]},
                {["T2"], ["a"]},
                {["V2"], ["T2", "T3"]},
                {["T3"], ["b"]},
                {["A"], ["T2", "V2"]},
                {["S"], ["A", "V1"]}
              ], initial}
  end
end
