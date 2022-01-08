defmodule Parser do
  @type ruleset :: [{charlist, charlist}]
  @type grammar :: {charlist, charlist, ruleset, char}
  @spec parse([char], grammar) :: boolean
  def parse(w, {non_terminal, terminal, ruleset, initial}) do
    # Mede a cadeia e então gera a linguagem (com sentenciais)
    #conforme a gramática até aquele tamanho
    size = length(w)
    language = generate([initial], ruleset, size)

    # Verifica se a cadeia pertence a linguagem
    w in language
  end

  def generate(ti, ruleset, max_length) do
    # Gera o próximo conjunto Ti+1 a partir do conjunto de sentenças anterior (Ti)
    # Para cada sentença em Ti realiza derivações com a função transform
    # Joga fora sentenças geradas que são repetidas (uniq)
    ti_1 = Enum.reduce(ti, [], &transform(&1, ruleset, max_length, &2)) |> Enum.uniq()

    # Para printar os passos de derivação descomente a linha abaixo
    # IO.inspect(ti_1)

    # Verifica se o conjunto gerado tem os mesmos elementos (é igual) ao anterior
    # Caso tenha, o conjunto obtido é o final, caso contrário recursão com o novo conjunto
    # TODO (Possível otimização: rodar transform apenas em novos elementos)
    if ti_1 -- ti == [] do
      ti
    else
      generate(ti_1, ruleset, max_length)
    end
  end

  def transform(w, ruleset, max_length, acc) do
    # Para cada regra de derivação gera uma lista de derivações se possível
    # Depois filtra as que são maiores que o tamanho máximo
    tw = ruleset |> Enum.flat_map(&transform(w, &1)) |> Enum.filter(&length(&1) <= max_length)

    # Adiciona a sentença inicial, perdida durante as derivações
    # Bem como o acumulador para funcionar no reduce
    [w] ++ tw ++ acc
  end
  def transform(w, {a, b}) do
    # Mede o tamanho do elemento que estamos buscando para substituir
    size = length(a)

    # Agrupa a sentença em blocos do tamanho do elemento para facilitar a comparação
    # Verifica os grupos recursivamente
    w |> Enum.chunk_every(size, 1, :discard) |> apply_rule(w, {a,b}, [], size, 0)
  end

  defp apply_rule([head | tail], original, {a, b}, t, _rule_size, index) do
    # Se o padrão do primeiro bloco corresponde a regra, substitui
    if head == a do
      # Quebra a sentença em 3 partes:
      # - prefixo
      # - o elemento que vai ser substituido
      # - sufixo
      {prefix, suffix} = Enum.split(original, index)
      suffix = suffix -- a

      # Reconstroi a sentença substituindo o elemento
      # Adiciona ele na lista de derivações com essa regra
      t = [prefix ++ b ++ suffix] ++ t
      apply_rule(tail, original, {a,b}, t, _rule_size, index + 1)
    else
      # O padrão não foi encontrado, então só incrementa o índice
      apply_rule(tail, original, {a,b}, t, _rule_size, index + 1)
    end
  end
  defp apply_rule([], _original, _ruleset, t, _rule_size, index) do
    t
  end
end