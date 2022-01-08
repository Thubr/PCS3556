defmodule Parser do
  use Agent
  @type symbol :: String.t() | atom
  @type ruleset :: [{[symbol], [symbol]}]
  @type grammar :: {[symbol], [symbol], ruleset, symbol}
  @spec parse(String.t(), grammar) :: boolean
  def parse(w, {_nonterminal, terminal, ruleset, initial}) do
    start_memo(terminal, ruleset)
    ruleset = Enum.filter(ruleset, fn {_left, right} -> length(right) > 1 end)
    cyk(w, ruleset, 2)
    memo = Agent.get(__MODULE__, & &1)
    #    IO.inspect(memo)
    Enum.member?(memo[w], initial)
  end

  def cyk(w, ruleset, size) do
    chunked = Enum.chunk_every(w, size, 1, :discard)
    Enum.each(chunked, &cyk(&1, ruleset, 0, []))

    if(length(w) > size) do
      cyk(w, ruleset, size + 1)
    end
  end

  def cyk(chunk, ruleset, index, acc) do
    memo = Agent.get(__MODULE__, & &1)

    if(Map.has_key?(memo, chunk)) do
      #      IO.inspect(chunk, label: "Has memo")
      memo[chunk]
    else
      #      IO.inspect(chunk, label: "Doesn't has memo")
      cyk_new(chunk, memo, ruleset, index, acc)
    end
  end

  def cyk_new(chunk, memo, ruleset, index, acc) do
    if(length(chunk) > index + 1) do
      {prefix, suffix} = Enum.split(chunk, index + 1)

      if(
        memo[prefix] != nil and memo[prefix] != [] and memo[suffix] != nil and memo[suffix] != []
      ) do
        prefix = memo[prefix]
        suffix = memo[suffix]

        f =
          ruleset
          |> Enum.filter(fn {_left, [head, tail]} ->
            Enum.member?(prefix, head) and Enum.member?(suffix, tail)
          end)
          |> Enum.flat_map(fn {left, _right} -> left end)

        acc = f ++ acc
        cyk_new(chunk, memo, ruleset, index + 1, acc)
      else
        cyk_new(chunk, memo, ruleset, index + 1, acc)
      end
    else
      memoize(chunk, Enum.uniq(acc))
    end
  end

  def start_memo(terminal, ruleset) do
    memo =
      ruleset
      |> Enum.filter(fn {_left, right} -> Enum.member?(terminal, hd(right)) end)
      |> Enum.map(fn {left, right} -> {right, left} end)
      |> Map.new()

    Agent.start_link(fn -> memo end,
      name: __MODULE__
    )
  end

  def memoize(input, output) do
    Agent.update(__MODULE__, &Map.update(&1, input, output, fn val -> output ++ val end))
  end
end
