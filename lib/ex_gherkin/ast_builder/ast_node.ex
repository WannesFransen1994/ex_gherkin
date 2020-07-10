defmodule ExGherkin.AstNode do
  @me __MODULE__
  defstruct rule_type: nil, subitems: %{}
  require IEx

  # Uhm apparently in gherkindocbuilder
  def add_subitem(%@me{} = node, ruletype, token_or_node) do
    new_subitems =
      case Map.fetch(node.subitems, ruletype) do
        {:ok, list_of_items} -> %{node | subitems: [token_or_node | list_of_items]}
        :error -> Map.put_new(node.subitems, ruletype, [token_or_node])
      end

    %{node | subitems: new_subitems}
  end
end
