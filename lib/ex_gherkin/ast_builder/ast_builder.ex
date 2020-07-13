defmodule ExGherkin.AstBuilder do
  alias ExGherkin.{ParserContext, AstNode, Token, RuleTypes, TokenTypes}
  alias CucumberMessages.GherkinDocument.Comment
  alias CucumberMessages.GherkinDocument.Feature.Tag, as: MessageTag
  alias CucumberMessages.GherkinDocument.Feature.Step, as: StepMessage
  alias CucumberMessages.GherkinDocument.Feature.Step.DataTable, as: DataTableMessage
  alias CucumberMessages.GherkinDocument.Feature.TableRow, as: TableRowMessage
  alias CucumberMessages.GherkinDocument.Feature.TableRow.TableCell, as: TableCellMessage

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
    transformed_node = transform_node(to_be_transformed)
    {%AstNode{} = current_node, %Stack{} = new_stack} = Stack.pop(stack)
    # add transformed node to current node with ruletype? line 75 in gherk doc builder
    # NOTE: using token type here, in java it uses the enum ordinal to get the
    #  Rule type, but doesn't this always match...? Just passing token type, see what happens
    updated_node =
      AstNode.add_subitem(current_node, to_be_transformed.rule_type, transformed_node)

    updated_builder = %{builder | stack: Stack.push(new_stack, updated_node)}
    if context.state in [15, 41], do: IEx.pry()
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

  defp transform_node(%AstNode{rule_type: Step} = node) do
    # TODO: ID GENERATOR
    token = AstNode.get_token(node, StepLine)

    %StepMessage{
      id: "0",
      keyword: token.matched_keyword,
      location: Token.get_location(token),
      text: token.matched_text
    }
    |> add_datatable_to_step_message(AstNode.get_single(node, DataTable, nil))
    |> add_docstring_to_step_message(AstNode.get_single(node, DocString, nil))
  end

  defp transform_node(%AstNode{rule_type: DocString} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: DataTable} = node) do
    rows = get_table_rows(node)
    location = rows |> List.first() |> Map.fetch!(:location)

    %DataTableMessage{location: location, rows: rows}
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
    result =
      Enum.map(
        ExGherkin.AstNode.get_tokens(node, TableRow),
        fn %Token{} = t ->
          # TODO: Replace ID
          %TableRowMessage{id: "0", location: Token.get_location(t), cells: get_cells(t)}
        end
      )
      |> Enum.reverse()

    # TODO: ensure_cell_count
    result
  end

  # defp ensure_cell_count(table_rows) when is_list(table_rows) do
  #   # TODO: Implement
  # end

  defp get_cells(%Token{items: items} = token) do
    base_location = %CucumberMessages.Location{} = Token.get_location(token)

    Enum.map(items, fn item ->
      updated_location = %{base_location | column: item.column}
      %TableCellMessage{location: updated_location, value: item.content}
    end)
  end

  defp get_tags(node) do
    with tag_node when not tag_node == nil <-
           AstNode.get_single(node, RuleTypes.Tags, %AstNode{rule_type: RuleTypes.None}) do
      new_tokens_list = AstNode.get_tokens(tag_node, TokenTypes.TagLine)

      Enum.reduce(new_tokens_list, [], fn token, token_acc ->
        token_acc ++
          Enum.reduce(token.items, [], fn tag_item, tag_acc -> tag_acc ++ [MessageTag.new()] end)
      end)
    else
      nil -> []
    end
  end

  defp add_datatable_to_step_message(%StepMessage{} = m, nil), do: m
  defp add_datatable_to_step_message(%StepMessage{} = m, d), do: %{m | argument: {:data_table, d}}
  defp add_docstring_to_step_message(%StepMessage{} = m, nil), do: m
  defp add_docstring_to_step_message(%StepMessage{} = m, d), do: %{m | argument: {:doc_string, d}}
end
