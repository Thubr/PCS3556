defmodule Automata do
  @type transition :: {atom, {String.t(), atom}}
  @type config :: {atom, [transition], [atom]}
  @spec builder(config) :: boolean
  def builder({init_state, transitions, final_states}) do
    random_seed = :rand.uniform(100_000)
    module_name = String.to_atom("AutomataStateMachineModule#{random_seed}")

    ast =
      quote do
        use StateMachine,
          initial: unquote(init_state),
          final: unquote(final_states),
          transitions: unquote(transitions)
      end

    Module.create(module_name, ast, Macro.Env.location(__ENV__))
    module_name
  end
end
