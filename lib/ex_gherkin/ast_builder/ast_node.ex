defmodule ExGherkin.AstNode do
  @me __MODULE__
  defstruct rule_type: nil, subitems: %{}
  require IEx

  alias ExGherkin.{AstNode, RuleTypes}

  # Uhm apparently in gherkindocbuilder
  def add_subitem(%@me{} = node, ruletype, token_or_node) do
    new_subitems =
      case Map.fetch(node.subitems, ruletype) do
        {:ok, list_of_items} -> %{node | subitems: [token_or_node | list_of_items]}
        :error -> Map.put_new(node.subitems, ruletype, [token_or_node])
      end

    %{node | subitems: new_subitems}
  end

  def get_single(%AstNode{} = node, rule_type, defaultresult) do
    case get_items(node, rule_type) do
      [] -> defaultresult
      [head | _rest] -> head
    end
  end

  def get_items(%AstNode{subitems: subitems}, rule_type) do
    case Map.fetch(subitems, rule_type) do
      {:ok, list} -> list
      :error -> []
    end
  end

  def get_token(%AstNode{} = node, token_type) do
    # Is this necessary? Rule types obtained by following func will always be the same as token type?
    rule_type = RuleTypes.get_ruletype_for_tokentype(token_type)
    get_single(node, rule_type, %ExGherkin.Token{})
  end
end
