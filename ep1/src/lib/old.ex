#defmodule SetClosure do
#  @spec find_closure([boolean]) :: tuple()
#  def find_closure(relation) do
#    size = length(relation)
#    {List.flatten(relation), []} |> make_reflexive(size) |> make_transitive(size)
#  end
#
#  def make_reflexive({relation, closure}, size) do
#    Enum.map_every(relation, size+1, &(&1 or true))
#  end
#
#  def make_transitive(relation, size) do
#
#    make_transitive(relation, size, checklist) do
#  end
#
#  defp make_transitive(relation, size, checklist) do
#  end
#
#  defp make_transitive(relation, size, []) do
#    relation
#  end
#
#  defp is_transitive?(relation, size, {i,j}) do
#    relation[size*i + j]
#  end
#end