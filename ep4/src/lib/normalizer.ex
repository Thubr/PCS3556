defmodule Normalizer do
  use Agent
  @type symbol :: String.t() | atom
  @type ruleset :: [{[symbol], [symbol]}]
  @type grammar :: {[symbol], [symbol], ruleset, symbol}
  @spec normalize(grammar) :: grammar

  def normalize({non_terminal, terminal, ruleset, initial}) do
    start_grammar(non_terminal, terminal, initial)
    ruleset = ruleset |> fix_starter |> fix_nullable |> fix_unit |> fix_long |> fix_terminal
    {non_terminal, terminal, initial} = get_grammar()
    {non_terminal, terminal, ruleset, initial}
  end

  def fix_starter(ruleset) do
    {_, _, initial} = get_grammar()
    result = Enum.flat_map(ruleset, &fix_starter_map(&1, initial)) |> Enum.uniq()
    #    IO.inspect(result)
    result
  end

  defp fix_starter_map({left, right}, initial) do
    if(Enum.member?(right, initial)) do
      [{[change_initial()], [initial]}, {left, right}]
    else
      [{left, right}]
    end
  end

  # Cria uma lista com todas as variaveis que geram elementos nulos
  # E depois percorre ela com a função fix_nullable/2 para gerar uma lista com as novas regras
  # Retorna o ruleset modificado
  def fix_nullable(ruleset) do
    only_nullable = Enum.filter(ruleset, fn {_, right} -> right == :epsilon end)
    filtered = ruleset -- only_nullable
    #    IO.inspect(filtered)
    nullable = Enum.map(only_nullable, fn {[symbol], _} -> symbol end)
    result = Enum.reduce(nullable, filtered, &fix_nullable(&1, &2))
    #    IO.inspect(result)
    result
  end

  # Para cada regra do ruleset que possui o elemento anulavel executa a funcao replace_nullable/4
  # Retorna uma lista de novas regras desse elemento anulavel
  def fix_nullable(nullable, ruleset) do
    acc =
      ruleset
      |> Enum.filter(fn {_, right} -> Enum.member?(right, nullable) end)
      |> Enum.flat_map(&replace_nullable(&1, nullable, [&1], []))

    (acc ++ ruleset) |> Enum.uniq()
  end

  # Para cada regra realiza um passo de derivação nula (eliminando uma ocorrencia do elemento nullable)
  # Repete a derivacao em cima das regras geradas até que seja gerada uma regra sem nenhum elemento nullable
  # Retorna a lista com todas as novas regras criadas
  defp replace_nullable({left, right}, nullable, new_rules, acc) do
    if(Enum.member?(right, nullable)) do
      #      IO.inspect(new_rules)
      new_rules =
        Enum.reduce(new_rules, [], fn {left, right}, ac ->
          replace_nullable_step(
            {left, right},
            nullable,
            right,
            -1,
            ac
          )
        end)

      #      IO.inspect(new_rules)
      replace_nullable(hd(new_rules), nullable, new_rules, new_rules ++ acc)
    else
      acc
    end
  end

  # Gera as derivacoes com um passo de profundidade
  defp replace_nullable_step({left, right}, nullable, suffix, index, acc) do
    replace = Enum.find_index(suffix, &(&1 == nullable))
    #    IO.inspect(replace)
    if(replace != nil) do
      {prefix, [_ | suffix]} = Enum.split(right, replace + index + 1)
      #      IO.inspect(suffix)
      replace_nullable_step(
        {left, right},
        nullable,
        suffix,
        replace + index + 1,
        [{left, prefix ++ suffix}] ++ acc
      )
    else
      acc
    end
  end

  def fix_long(ruleset) do
    long_rules = Enum.filter(ruleset, fn {left, right} -> length(right) > 2 end)
    fixed = ruleset -- long_rules
    result = fixed ++ Enum.flat_map(long_rules, &break_long(&1))
    #    IO.inspect(result)
    result
  end

  defp break_long({left, right}) do
    {steps, final} = Enum.split(right, length(right) - 2)

    new_rules =
      Enum.reduce(
        tl(steps),
        [{left, [hd(right), new_symbol(:non_terminal)]}],
        &break_long(&1, &2)
      )

    [{_, [_ | last]} | _] = new_rules
    [{last, final}] ++ new_rules
  end

  defp break_long(symbol, acc) do
    [{_, [_ | last]} | _] = acc
    [{last, [symbol, new_symbol(:non_terminal)]}] ++ acc
  end

  def fix_terminal(ruleset) do
    {_, terminal, _} = get_grammar()

    filtered =
      Enum.filter(ruleset, fn {left, right} -> Enum.any?(right, &Enum.member?(terminal, &1)) end)

    new_rules = Enum.flat_map(filtered, &break_terminal(&1, terminal)) |> Enum.uniq()
    ruleset = ruleset -- filtered
    result = new_rules ++ ruleset
    #    IO.inspect(result)
    result
  end

  defp break_terminal({left, right}, terminals) do
    cond do
      Enum.all?(right, &Enum.member?(terminals, &1)) ->
        [head | tail] = right
        terminal1 = new_symbol(:terminal, head)
        terminal2 = new_symbol(:terminal, hd(tail))
        [{left, [terminal1, terminal2]}, {[terminal1], [head]}, {[terminal2], tail}]

      Enum.member?(terminals, hd(right)) ->
        [head | tail] = right
        terminal = new_symbol(:terminal, head)
        [{left, [terminal] ++ tail}, {[terminal], [head]}]

      Enum.member?(terminals, hd(tl(right))) ->
        [head | tail] = right
        terminal = new_symbol(:terminal, hd(tail))
        [{left, [head] ++ [terminal]}, {[terminal], tail}]
    end
  end

  def fix_unit(ruleset) do
    {nonterminal, terminal, _} = get_grammar()
    # Filtra apenas as regras de producao unitaria de nao terminais
    filtered =
      Enum.filter(ruleset, fn {left, right} ->
        is_atom(right) or (length(right) < 2 and Enum.member?(nonterminal, hd(right)))
      end)

    # Cria uma lista dos simbolos que realizam producao unitaria
    unit_producers = filtered |> Enum.map(fn {left, right} -> left end) |> Enum.uniq()
    # Encontra o fecho transitivo do conjunto de regras
    transitive_closure = SetClosure.make_transitive(ruleset)
    # Filtra apenas as novas regras, removendo tambem as intermediarias
    new_rules =
      Enum.filter(transitive_closure -- ruleset, fn {left, right} ->
        Enum.member?(unit_producers, left) and
          (length(right) >= 2 or Enum.member?(terminal, hd(right)))
      end)

    # Remove as producoes unitarias
    ruleset = ruleset -- filtered
    # Adiciona as novas regras produzidas
    result = ruleset ++ new_rules
    #    IO.inspect(result)
    result
  end

  def start_grammar(non_terminal, terminal, initial) do
    # Inicializar com simbolos nao existentes
    stream = Stream.iterate(1, &(&1 + 1))
    vocabulary = non_terminal ++ terminal

    nt = Enum.find(stream, &(!(("V" <> to_string(&1)) in vocabulary)))
    t = Enum.find(stream, &(!(("T" <> to_string(&1)) in vocabulary)))
    init = Enum.find(stream, &(!(("S" <> to_string(&1)) in vocabulary)))
    tmap = %{}

    Agent.start_link(fn -> [{nt, t, init, tmap}, {non_terminal, terminal, initial}] end,
      name: __MODULE__
    )
  end

  def new_symbol(:non_terminal) do
    Agent.get_and_update(__MODULE__, fn [
                                          {nt, t, init, tmap}
                                          | [{non_terminal, terminal, initial}]
                                        ] ->
      {"V" <> to_string(nt),
       [{nt + 1, t, init, tmap}, {["V" <> to_string(nt)] ++ non_terminal, terminal, initial}]}
    end)
  end

  def new_symbol(:terminal, t) do
    Agent.get_and_update(__MODULE__, &fetch_terminal(&1, t))
  end

  defp fetch_terminal([{nt, t, init, tmap} | [{non_terminal, terminal, initial}]], key) do
    if(Map.has_key?(tmap, key)) do
      {tmap[key], [{nt, t, init, tmap}, {non_terminal, terminal, initial}]}
    else
      val = "T" <> to_string(t)
      tmap = Map.put(tmap, key, val)
      {val, [{nt, t + 1, init, tmap}, {[val] ++ non_terminal, terminal, initial}]}
    end
  end

  def change_initial() do
    Agent.get_and_update(__MODULE__, fn [
                                          {nt, t, init, tmap}
                                          | [{non_terminal, terminal, initial}]
                                        ] ->
      {"S" <> to_string(init),
       [
         {nt, t, init, tmap},
         {["S" <> to_string(init)] ++ non_terminal, terminal, "S" <> to_string(init)}
       ]}
    end)
  end

  def get_grammar() do
    Agent.get(__MODULE__, fn [_ | tail] -> hd(tail) end)
  end
end
