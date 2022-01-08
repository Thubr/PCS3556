defmodule StateMachine do
  defmacro __using__(opts) do
    # Le todos os parametros
    initial = Keyword.get(opts, :initial)
    final = Keyword.get(opts, :final)
    transitions = Keyword.get(opts, :transitions)

    # Constroi as funcoes de transicao
    transitions = Enum.map(transitions, &build_transition(&1))
    # Constroi as funcoes de estado final
    final = Enum.map(final, &build_final(&1))

    quote do
      # Insere as funcoes específicas que especificam o automato
      unquote_splicing(transitions)
      unquote_splicing(final)
      # Casos complementares
      def transition(_, _), do: :error
      def final?(_), do: false

      # Roda o automato com uma cadeia, iniciando pelo estado inicial
      def run(tape) do
        run(tape, [unquote(initial)])
      end

      defp run(_, :error) do
        false
      end

      defp run(tape, states) do
        # Le o simbolo atual
        t = Tape.at(tape)

        # Se for o final da fita, confere se estah num estado de aceitacao
        if t == "$" do
          Enum.any?(states, &final?(&1))
        else
          # Move o cabecote
          Tape.reconfig!(tape)

          # Caso houver mais de um caminho possivel, executa até que um aceite a fita
          # ou esgotar a fita
          if length(states) > 1 do
            Enum.any?(states, &clone_run(tape, &1, t))
          else
            run(tape, transition(hd(states), t))
          end
        end
      end

      # Clona o estado da fita atual e roda uma nova simulação
      defp clone_run(tape, state, t) do
        [left, right] = Tape.contents(tape)
        {:ok, tape} = Tape.init(left, right)
        run(tape, transition(state, t))
      end
    end
  end

  # Para cada transicao cria uma funcao que retorna o proximo estado para
  # um conjunto (estado atual, transicao) de entrada
  defp build_transition({state, {symbol, next_state}}) do
    quote do
      def transition(unquote(state), unquote(symbol)), do: unquote(next_state)
    end
  end

  # Constroi as funcoes que representam estados finais
  defp build_final(state) do
    quote do
      def final?(unquote(state)), do: true
    end
  end
end
