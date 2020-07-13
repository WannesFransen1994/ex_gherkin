defmodule ExGherkin.AstBuilder do
  alias ExGherkin.{ParserContext, AstNode, Token}
  alias CucumberMessages.GherkinDocument.Comment
  @me __MODULE__

  require IEx
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
    # transformed_node = to_be_transformed
    # Logger.warn("YOU REALLY NEED TO IMPLEMENT THIS")
    # if context.state in [3, 12, 15, 41], do: IEx.pry()
    transformed_node = transform_node(to_be_transformed)
    {%AstNode{} = current_node, %Stack{} = new_stack} = Stack.pop(stack)
    # add transformed node to current node with ruletype? line 75 in gherk doc builder
    # NOTE: using token type here, in java it uses the enum ordinal to get the
    #  Rule type, but doesn't this always match...? Just passing token type, see what happens
    updated_node = AstNode.add_subitem(current_node, transformed_node.rule_type, transformed_node)
    updated_builder = %{builder | stack: Stack.push(new_stack, updated_node)}
    %{context | ast_builder: updated_builder}
  end

  def build(%ParserContext{ast_builder: %@me{} = builder} = context) do
    token = context.current_token

    case token.matched_type do
      Comment ->
        loc = Token.get_location(token)
        comment_message = %Comment{location: loc, text: token.line.content}
        updated_comments = [comment_message | builder.gherkin_doc.comments]
        updated_gherkin_doc = %{builder.gherkin_doc | comments: updated_comments}
        updated_builder = %{builder | gherkin_doc: updated_gherkin_doc}
        %{context | ast_builder: updated_builder}

      other_type ->
        {%AstNode{} = current, %Stack{} = temp_stack} = Stack.pop(builder.stack)
        updated_node = AstNode.add_subitem(current, other_type, token)
        updated_builder = %{builder | stack: Stack.push(temp_stack, updated_node)}
        %{context | ast_builder: updated_builder}
    end
  end

  alias CucumberMessages.GherkinDocument.Feature.Step, as: StepMessage
  alias CucumberMessages.GherkinDocument.Feature.Step.DataTable, as: DataTableMessage

  defp transform_node(%AstNode{rule_type: Step = rtype} = node) do
    # TODO: ID GENERATOR
    token = AstNode.get_token(node, StepLine)
    loc = Token.get_location(token)

    step = %StepMessage{
      id: 0,
      keyword: token.matched_keyword,
      location: loc,
      text: token.matched_text
    }

    data_table =
      case AstNode.get_single(node, DataTable, nil) do
        nil ->
          nil

        raw_data ->
          IEx.pry()
          %DataTableMessage{location: -1, rows: []}
      end

    # node_with_possible_data_table = case data_table do
    #   nil -> node
    #   data -> %{step | }
    # end

    require IEx
    IEx.pry()
    # raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: DocString} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: DataTable} = node) do
    rows = get_table_rows(node)

    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: Background} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: ScenarioDefinition} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: ExamplesDefinition} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: ExamplesTable} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: Description} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: Feature} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: Rule} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: GherkinDocument} = node) do
    # TODO: actually transform
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(node), do: node

  defp get_table_rows(%AstNode{} = node) do
    require IEx
    IEx.pry()
  end
end
