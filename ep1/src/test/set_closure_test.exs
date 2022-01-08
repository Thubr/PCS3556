defmodule SetClosureTest do
  use ExUnit.Case

#   @tag :pending
  test "reflexive property: is working" do
    set = [1,2,3,4,5]
    relation = [{1,1}, {1,4}, {2,3}, {4,5}, {5,1}]
    identity = [{1,1}, {2,2}, {3,3}, {4,4}, {5,5}]
    result = SetClosure.make_reflexive(relation, set)
    assert result != relation
    assert result -- identity == relation -- [{1,1}]
  end

  #   @tag :pending
  test "reflexive property: identity is preserved" do
    set = [1,2,3,4,5]
    identity = [{1,1}, {2,2}, {3,3}, {4,4}, {5,5}]
    result = SetClosure.make_reflexive(identity, set)
    assert result == identity
  end

  #   @tag :pending
  test "reflexive property: fill with new elements" do
    set = [1,2,3,4,5]
    relation = [{1,2}, {2,3}]
    identity = [{1,1}, {2,2}, {3,3}, {4,4}, {5,5}]
    result = SetClosure.make_reflexive(relation, set)
    assert result != relation
    assert result -- identity == relation
  end

#  @tag :pending
  test "transitive property: is working" do
    relation = [{1,1}, {1,4}, {2,3}, {4,5}, {5,1}]
    expected = [{5, 5}, {5, 4}, {4, 4}, {4, 1}, {1, 5}, {1, 1}, {1, 4}, {2, 3}, {4, 5}, {5, 1}]
    result = SetClosure.make_transitive(relation)
    assert result != relation
    assert result -- expected == []
  end

#  @tag :pending
  test "transitive property: transitive is preserved" do
    relation = [{1,2}, {2,3}, {1,3}]
    result = SetClosure.make_transitive(relation)
    assert result -- relation == []
  end

#  @tag :pending
  test "reflexive and transitive closure: is working" do
    set = [1,2,3,4,5]
    relation = [{1,1}, {1,4}, {2,3}, {4,5}, {5,1}]
    expected = [{5, 5}, {5, 4}, {4, 4}, {4, 1}, {1, 5}, {1, 1}, {1, 4}, {2, 2}, {2, 3}, {3, 3}, {4, 5}, {5, 1}]
    result = SetClosure.find_closure(relation, set)
    assert result != relation
    assert result -- expected == []
  end

#  @tag :pending
  test "reflexive and transitive closure: preserve closure" do
    set = [1,2,3]
    relation = [{1,1}, {1, 2}, {2, 2}, {2, 3}, {3, 3}, {1, 3}]
    result = SetClosure.find_closure(relation, set)
    assert result -- relation == []
  end
end
