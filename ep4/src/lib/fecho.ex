defmodule SetClosure do
  @spec find_closure([tuple], [integer]) :: tuple()
  def find_closure(relation, set) do
    relation |> make_reflexive(set) |> make_transitive
  end

  def make_reflexive(relation, set) do
    found = count(relation, [])
    needed = set -- found
    fill(relation, needed)
  end

  defp fill(relation, [head | tail]) do
    fill([{head, head}] ++ relation, tail)
  end

  defp fill(relation, []) do
    relation
  end

  defp count([{i, j} | tail], acc) do
    if i == j do
      count(tail, [i] ++ acc)
    else
      count(tail, acc)
    end
  end

  defp count([], acc) do
    acc
  end

  def make_transitive(relation) do
    tree = build_tree(relation, %{})
    transitive_closure = make_transitive(tree, Map.keys(tree), [])
    transitive_closure ++ relation
  end

  defp make_transitive(tree, [head | tail], closure) do
    {closure, tree} = dfs(tree[head], head, tree, closure)
    make_transitive(tree, tail, closure)
  end

  defp make_transitive(_tree, [], closure) do
    closure
  end

  defp dfs([head | tail], current, tree, acc) do
    # Complete current tree with remaining sibling connections
    if Map.has_key?(tree, head) do
      remaining = tree[head] -- tree[current]
      tail = remaining ++ tail
      tree = %{tree | current => remaining ++ tree[current]}
      acc = Enum.map(remaining, &{current, &1}) ++ acc
      dfs(tail, current, tree, acc)
    else
      dfs(tail, current, tree, acc)
    end
  end

  defp dfs([], _current, tree, acc) do
    {acc, tree}
  end

  defp build_tree([{i, j} | tail], acc) do
    if Map.has_key?(acc, i) do
      acc = %{acc | i => [j] ++ acc[i]}
      build_tree(tail, acc)
    else
      acc = Map.put(acc, i, [j])
      build_tree(tail, acc)
    end
  end

  defp build_tree([], acc) do
    acc
  end
end
