defmodule Tape do
  @typedoc "Return values of `start*` functions"
  @type on_start :: {:ok, pid} | {:error, {:already_started, pid} | term}

  use Agent

  @doc """
  Inicializa a fita t.
  A fita tem o formato [left, right], onde:
  left: elementos à esquerda do cabeçote
  right: elementos à direita do cabeçote
  O cabeçote está posicionado no primeiro elemento da lista right
  """
  @spec init([String.t()]) :: on_start()
  def init(content) do
    # $ indica o começo da fita
    Agent.start_link(fn -> [["$"], content] end)
  end

  @spec init([String.t()], [String.t()]) :: on_start()
  def init(left, right) do
    # $ indica o começo da fita
    Agent.start_link(fn -> [left, right] end)
  end

  @doc """
  Retorna uma cópia do elemento lido pelo cabeçote da fita
  """
  @spec at(pid) :: String.t()
  def at(tape) do
    # Retorna "$" para indicar o fim da fita
    Agent.get(tape, &read_head(&1))
  end

  defp read_head([_head | tail]) do
    t = hd(tail)

    if t == [] do
      "$"
    else
      hd(t)
    end
  end

  @doc """
  Move o cabeçote para direita
  """
  @spec reconfig!(pid) :: atom
  def reconfig!(tape) do
    # Gera um erro caso a fita já esteja vazia
    Agent.update(tape, &move_right!(&1))
  end

  defp move_right!([head | tail]) do
    [head ++ [hd(hd(tail))], tl(hd(tail))]
  end

  @doc """
  Retorna todo conteúdo da fita no formato [left, right]
  """
  @spec contents(pid) :: [[String.t()]]
  def contents(tape) do
    Agent.get(tape, & &1)
  end
end
