defmodule ExGherkin.AstBuilder do
  alias ExGherkin.{ParserContext, AstNode, Token}
  alias CucumberMessages.GherkinDocument.Comment
  alias CucumberMessages.GherkinDocument.Feature.Tag, as: MessageTag
  alias CucumberMessages.GherkinDocument.Feature.Scenario, as: MessageScenario
  alias CucumberMessages.Location
  alias CucumberMessages.GherkinDocument.Feature.Step, as: StepMessage
  alias CucumberMessages.GherkinDocument.Feature.Step.DataTable, as: DataTableMessage
  alias CucumberMessages.GherkinDocument.Feature.TableRow, as: TableRowMessage
  alias CucumberMessages.GherkinDocument.Feature.TableRow.TableCell, as: TableCellMessage
  alias CucumberMessages.GherkinDocument.Feature, as: FeatureMessage
  alias CucumberMessages.GherkinDocument.Feature.FeatureChild, as: FeatureChildMessage

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
    if context.state in [15], do: IEx.pry()
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
    |> add_datatable_to(AstNode.get_single(node, DataTable, nil))
    |> add_docstring_to(AstNode.get_single(node, DocString, nil))
  end

  defp transform_node(%AstNode{rule_type: DocString} = node) do
    line_tokens = AstNode.get_tokens(node,Other)
    content = Enum.reduce(line_tokens,[],fn line_token, acc -> acc ++ ["\n",line_token.matchedText] end)
    Enum.join(content," ")
    # case AstNode.get_tokens(node, DocStringSeparator) do
    #   [] -> nil  #TODO: Fix if list is empty!
    #   [seperatorToken | _] ->
    # end
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
    tags = get_tags(node)
    scenario_node = AstNode.get_single(node, Scenario, nil)
    scenario_line = AstNode.get_token(scenario_node, ScenarioLine)
    description = get_description(scenario_node)
    steps = get_steps(scenario_node)
    example_list = AstNode.get_items(scenario_node, ExamplesDefinition)
    loc = get_location(scenario_line, 0)
    # TODO: Generate ID
    %MessageScenario{
      description: description,
      id: "0",
      location: loc,
      keyword: scenario_line.matched_keyword,
      name: scenario_line.matched_text,
      tags: tags,
      steps: steps,
      examples: example_list
    }
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

  defp transform_node(%AstNode{rule_type: Feature} = n) do
    require IEx
    header_func = &AstNode.get_single(&1, FeatureHeader, %AstNode{rule_type: FeatureHeader})
    featureline_func = &AstNode.get_token(&1, FeatureLine)

    with {:header?, %AstNode{} = header} <- {:header?, header_func.(n)},
         {:feature_l?, %Token{} = fl} <- {:feature_l?, featureline_func.(header)},
         {:dialect?, dialect} when dialect != nil <- {:dialect?, fl.matched_gherkin_dialect} do
      background = AstNode.get_single(n, Background, nil)
      scen_def_items = AstNode.get_items(n, ScenarioDefinition)
      rule_items = AstNode.get_items(n, Rule)

      %FeatureMessage{
        tags: get_tags(header),
        language: dialect,
        location: Token.get_location(fl),
        keyword: fl.matched_keyword,
        name: fl.matched_text,
        description: get_description(header)
      }
      |> add_background_to(background)
      |> add_scen_def_children_to(scen_def_items)
      |> add_rule_children_to(rule_items)
    else
      {:header?, _} -> IEx.pry()
      {:feature_l?, _} -> IEx.pry()
      {:dialect?, _} -> IEx.pry()
    end
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

  defp get_location(%Token{} = token, column) do
    index =
      case column do
        0 -> token.indent
        other -> other
      end

    line = Token.get_location(token).line
    %Location{line: line, column: index}
  end

  defp get_steps(node) do
    AstNode.get_items(node, Step)
  end

  defp get_description(node) do
    AstNode.get_single(node, Description, "")
  end

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

  defp get_tags(node),
    do: node |> AstNode.get_single(Tags, %AstNode{rule_type: None}) |> process_tags

  # Even possible?
  defp process_tags(nil), do: []

  defp process_tags(%AstNode{} = tag_node) do
    tag_node
    |> AstNode.get_tokens(TagLine)
    |> Enum.reduce([], fn token, token_acc ->
      sub_result =
        Enum.reduce(token.items, [], fn tag_item, tag_acc ->
          loc = get_location(token, tag_item.column)
          # TODO: Generate ID
          message = %MessageTag{location: loc, name: tag_item.name, id: "0"}
          [message | tag_acc]
        end)
        |> Enum.reverse()

      [sub_result | token_acc]
    end)
    |> Enum.reverse()
  end

  defp add_datatable_to(%StepMessage{} = m, nil), do: m
  defp add_datatable_to(%StepMessage{} = m, d), do: %{m | argument: {:data_table, d}}
  defp add_docstring_to(%StepMessage{} = m, nil), do: m
  defp add_docstring_to(%StepMessage{} = m, d), do: %{m | argument: {:doc_string, d}}
  defp add_background_to(%FeatureMessage{} = m, nil), do: m

  defp add_background_to(%FeatureMessage{} = m, d) do
    require IEx
    IEx.pry()
    child = %FeatureChildMessage{value: {:background, d}}
    %{m | children: [child | m.children]}
  end

  defp add_scen_def_children_to(%FeatureMessage{} = m, scenario_definition_items) do
    scenario_definition_items
    |> Enum.reduce(m, fn scenario_def, feature_message_acc ->
      child = %FeatureChildMessage{value: {:scenario, scenario_def}}
      %{feature_message_acc | children: [child | feature_message_acc.children]}
    end)
  end

  defp add_rule_children_to(%FeatureMessage{} = m, rule_items) do
    rule_items
    |> Enum.reduce(m, fn rule, feature_message_acc ->
      require IEx
      IEx.pry()
      child = %FeatureChildMessage{value: {:rule, rule}}
      %{feature_message_acc | children: [child | feature_message_acc.children]}
    end)
  end
end
