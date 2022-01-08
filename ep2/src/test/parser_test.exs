defmodule ParserTest do
  use ExUnit.Case

#     @tag :pending
  test "transform is working for |a| = 1" do
    assert Parser.transform('abSabS', [{'S', 'a'},{'S', 'b'}], 6, []) -- ['abSabS', 'abaabS', 'abSabb', 'abSaba', 'abbabS'] == []
    assert Parser.transform('ab', [{'S', 'a'},{'S', 'b'}], 6, []) == ['ab']
  end

#     @tag :pending
  test "parser is working for |a| = 1" do
    p = [{'S', 'ab'},{'S', 'aA'},{'A', 'Bb'},{'A', 'b'},{'B', 'aA'}]
    assert Parser.parse('aabb', {'SAB','ab',p, 'S'}) == true
    assert Parser.parse('aabbb',{'SAB','ab',p, 'S'}) == false
  end

#     @tag :pending
  test "parser is working for |a| > 1" do
    p = [{'S', 'aBC'},{'S', 'aSBC'},{'CB', 'BC'},{'aB', 'ab'},{'bB', 'bb'},{'bC', 'bc'}, {'cC', 'cc'}]
    grammar = {'SBC', 'abc', p, 'S'}
    assert Parser.parse('aabbcc', grammar) == true
    assert Parser.parse('aaabbbcc', grammar) == false
  end

#     @tag :pending
  test "parser is working for big sequence" do
    p = [{'S', 'aBC'},{'S', 'aSBC'},{'CB', 'BC'},{'aB', 'ab'},{'bB', 'bb'},{'bC', 'bc'}, {'cC', 'cc'}]
    grammar = {'SBC', 'abc', p, 'S'}
    assert Parser.parse('aaaaaaabbbbbbbccccccc', grammar) == false
  end

#     @tag :pending
  test "parser is working for big rules" do
    p = [{'S', 'AAAAAAABS'},{'AAAAAAA', 'aaaaaaaS'},{'B', 'b'},{'S', 'c'},{'A', 'BS'}]
    grammar = {'SAB', 'abc', p, 'S'}
    assert Parser.parse('aaaaaaacbc',grammar) == true
    assert Parser.parse('aaaaaaaacb',grammar) == false
  end
end
