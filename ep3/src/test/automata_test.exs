defmodule AutomataTest do
  use ExUnit.Case
  alias Automata
  @moduletag :capture_log
  doctest Automata

  test "module exists" do
    assert is_list(Automata.module_info())
    assert is_list(StateMachine.module_info())
  end

  test "is creating final state" do
    initial_state = :q1
    final_states = [:q3]

    transitions = [
      q1: {"a", [:q2]},
      q1: {"b", [:q3]},
      q2: {"a", [:q2]},
      q2: {"b", [:q3]}
    ]

    automata = Automata.builder({initial_state, transitions, final_states})
    assert automata.final?(:q3) == true
  end

  test "is working for deterministic automata" do
    initial_state = :q1
    final_states = [:q3]

    transitions = [
      q1: {"a", [:q2]},
      q1: {"b", [:q3]},
      q2: {"a", [:q2]},
      q2: {"b", [:q3]},
      q3: {"a", [:q3]},
      q3: {"b", [:q3]}
    ]

    automata = Automata.builder({initial_state, transitions, final_states})
    {_, accept_tape} = Tape.init(["a", "b", "a", "a"])
    {_, reject_tape} = Tape.init(["a", "a", "a", "a"])
    assert automata.run(accept_tape) == true
    assert automata.run(reject_tape) == false
  end

  test "is working for non-deterministic automata" do
    initial_state = :q0
    final_states = [:q2]

    transitions = [
      q0: {"a", [:q0, :q1]},
      q0: {"b", [:q1]},
      q1: {"a", [:q2]},
      q1: {"b", [:q0]},
      q2: {"a", [:q2]},
      q2: {"b", [:q2]}
    ]

    automata = Automata.builder({initial_state, transitions, final_states})
    {:ok, accept_tape} = Tape.init(["a", "a", "a", "a"])
    {:ok, reject_tape} = Tape.init(["a", "b", "b"])
    assert automata.run(accept_tape) == true
    assert automata.run(reject_tape) == false
  end

  test "is rejecting when input cannot be consumed" do
    initial_state = :q0
    final_states = [:q2]

    transitions = [
      q0: {"a", [:q1, :q3]},
      q1: {"a", [:q2]}
    ]

    automata = Automata.builder({initial_state, transitions, final_states})
    {:ok, tape} = Tape.init(["a", "a", "a"])
    assert automata.run(tape) == false
  end

  @tag :pending
  test "is working for automata with epsilon transitions" do
    initial_state = :q0
    final_states = [:q2]

    transitions = [
      q0: {"a", [:q1]},
      q1: {"b", [:q2]},
      q2: {:epsilon, [:q3]},
      q3: {:epsilon, [:q0]}
    ]

    automata = Automata.builder({initial_state, transitions, final_states})
    {:ok, accept_tape} = Tape.init(["a", "b", "a", "b"])
    {:ok, reject_tape} = Tape.init(["a", "b", "a", "a"])
    assert automata.run(accept_tape) == true
    assert automata.run(reject_tape) == false
  end
end
