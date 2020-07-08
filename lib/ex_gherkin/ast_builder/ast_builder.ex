defmodule ExGherkin.AstBuilder do
  alias ExGherkin.{ParserContext, AstNode}
  @me __MODULE__

  require Logger

  defstruct stack: %Stack{}, gherkin_doc: nil

  def new do
    root_node = %AstNode{rule_type: None}
    default_stack = %Stack{} |> Stack.push(root_node)
    %@me{stack: default_stack}
  end

  def start_rule(%ParserContext{ast_builder: %@me{stack: s} = builder} = context, type) do
    IO.puts("START_RULE\t#{context.state}\t#{type}")

    node_to_be_pushed = %AstNode{rule_type: type}
    updated_builder = %{builder | stack: Stack.push(s, node_to_be_pushed)}
    %{context | ast_builder: updated_builder}
  end

  def end_rule(%ParserContext{ast_builder: %@me{stack: s} = builder} = context, type) do
    IO.puts("END_RULE\t#{context.state}\t#{type}")

    {%AstNode{} = to_be_transformed, %Stack{} = stack} = Stack.pop(s)
    _transformed_node = transform_node(to_be_transformed)
    {%AstNode{} = current_node, %Stack{} = new_stack} = Stack.pop(stack)
    # add transformed node to current node with ruletype? line 75 in gherk doc builder
    updated_builder = %{builder | stack: Stack.push(new_stack, current_node)}
    %{context | ast_builder: updated_builder}
  end

  def build(context) do
    # TODO: see what I actually should do here
    context
  end

  defp transform_node(node) do
    # TODO: actually transform
    node
  end
end
