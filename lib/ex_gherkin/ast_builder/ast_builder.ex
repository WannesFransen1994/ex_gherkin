defmodule ExGherkin.AstBuilder do
  alias ExGherkin.{ParserContext, AstNode, Token}
  alias CucumberMessages.GherkinDocument.Comment
  alias CucumberMessages.GherkinDocument.Feature.Tag, as: MessageTag
  alias CucumberMessages.GherkinDocument.Feature.Scenario, as: MessageScenario
  alias CucumberMessages.Location

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

  defp transform_node(%AstNode{rule_type: Step} = node) do
    # raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: DocString} = node) do
    raise "#{node.rule_type} implement me"
    node
  end

  defp transform_node(%AstNode{rule_type: DataTable} = node) do
    raise "#{node.rule_type} implement me"
    node
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
      id: 0,
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
    AstNode.get_single(node, Description, nil)
  end

  defp get_tags(node) do
    case AstNode.get_single(node, Tags, %AstNode{rule_type: None}) do
      nil ->
        []

      tag_node ->
        new_tokens_list = AstNode.get_tokens(tag_node, TagLine)

        Enum.reduce(new_tokens_list, [], fn token, token_acc ->
          token_acc ++
            Enum.reduce(token.items, [], fn tag_item, tag_acc ->
              loc = get_location(token, tag_item.column)
              # TODO: Generate ID
              message_tag = %MessageTag{location: loc, name: tag_item.name, id: 0}
              tag_acc ++ [message_tag]
            end)
        end)
    end
  end
end
