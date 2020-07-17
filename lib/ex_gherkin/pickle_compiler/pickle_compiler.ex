defmodule ExGherkin.PickleCompiler do
  defstruct id_gen: nil, pickles: [], language: nil, uri: nil

  alias CucumberMessages.GherkinDocument.Feature, as: FeatureMessage
  alias CucumberMessages.GherkinDocument.Feature.Scenario, as: ScenarioMessage
  alias CucumberMessages.GherkinDocument.Feature.Step, as: StepMessage
  alias CucumberMessages.GherkinDocument.Feature.TableRow, as: TableRowMessage
  alias CucumberMessages.Pickle, as: PickleMessage
  alias CucumberMessages.Pickle.PickleStep, as: PickleStepMessage
  alias CucumberMessages.Pickle.PickleTag, as: PickleTagMessage
  alias CucumberMessages.GherkinDocument.Feature.Tag, as: TagMessage

  @me __MODULE__
  require IEx

  def compile(%ExGherkin.AstBuilder{gherkin_doc: gherkin_doc, id_gen: id_generator}, uri) do
    me = %@me{id_gen: id_generator, uri: uri}
    _result = compile_feature(gherkin_doc.feature, me)
  end

  defp compile_feature(nil, %@me{pickles: p} = _compiler_acc), do: p

  defp compile_feature(%FeatureMessage{} = f, %@me{pickles: p, id_gen: i} = compiler_acc) do
    updated_compiler_acc = %{compiler_acc | language: f.language}
    meta_info = %{feature_backgr_steps: [], rule_backgr_steps: [], steps: [], pickles: []}

    result =
      Enum.reduce(f.children, {meta_info, updated_compiler_acc}, fn child, {m_acc, c_acc} ->
        case child.value do
          {:background, background} -> {%{m_acc | feature_backgr_steps: background.steps}, c_acc}
          {:rule, rule} -> IEx.pry()
          {:scenario, s} -> compile_scenario(m_acc, s, f.tags, c_acc)
        end
      end)

    IEx.pry()
  end

  # Match for a normal scenario. NOT a scenario outline. NO examples.
  defp compile_scenario(m, %ScenarioMessage{examples: []} = s, parent_tags, %@me{} = acc) do
    {steps, semi_updated_acc} =
      case s.steps do
        [] -> {[], acc}
        list_of_steps -> (m.feature_backgr_steps ++ list_of_steps) |> pickle_steps(acc)
      end

    pickle_tags = [parent_tags | s.tags] |> List.flatten() |> pickle_tags()
    {id, updated_compiler_acc} = get_id_and_update_compiler_acc(semi_updated_acc)

    new_msg = %PickleMessage{
      id: id,
      uri: acc.uri,
      name: s.name,
      language: acc.language,
      steps: steps,
      tags: pickle_tags,
      ast_node_ids: [s.id]
    }

    new_meta_info = %{m | pickles: [new_msg | m.pickles]}
    {new_meta_info, updated_compiler_acc}
  end

  # When there are examples, it is a scenario outline
  # defp compile_scenario(meta_info, %ScenarioMessage{} = scenario) do
  # end

  ####################
  # Helper functions #
  ####################
  defp pickle_tags(list_of_tag_messages), do: Enum.map(list_of_tag_messages, &pickle_tag/1)
  defp pickle_tag(%TagMessage{} = t), do: %PickleTagMessage{ast_node_id: t.id, name: t.name}

  defp pickle_steps(step_messages, %@me{} = acc) do
    {reversed_msges, new_acc} =
      Enum.reduce(step_messages, {[], acc}, fn message, {pickle_steps_acc, compiler_acc} ->
        {pickle_step, updated_acc} = pickle_step(message, compiler_acc)
        {[pickle_step | pickle_steps_acc], updated_acc}
      end)

    {Enum.reverse(reversed_msges), new_acc}
  end

  defp pickle_step(%StepMessage{} = m, %@me{} = acc), do: pickle_step_creator(m, [], nil, acc)

  # values row = TableRowMessage
  defp pickle_step_creator(%StepMessage{} = m, variable_cells, values_row, %@me{} = acc) do
    value_cells =
      case values_row do
        nil -> []
        data -> data.cells
      end

    step_text = interpolate(m.text, variable_cells, value_cells)
    {id, updated_compiler_acc} = get_id_and_update_compiler_acc(acc)

    message =
      %PickleStepMessage{id: id, ast_node_ids: [m.id], text: step_text}
      |> add_ast_node_id(values_row)
      |> add_datatable(m)
      |> add_doc_string(m)

    {message, updated_compiler_acc}
  end

  defp interpolate(text, variable_cells, value_cells) do
    variable_cells
    |> Enum.zip(value_cells)
    |> Enum.reduce(text, fn {variable_cell, value_cell}, text ->
      IEx.pry()
    end)

    # return interpolated text
  end

  ####################################################
  # Extra Helper functions to reduce "If nil" horror #
  ####################################################

  defp add_ast_node_id(%PickleStepMessage{} = m, nil), do: m

  defp add_ast_node_id(%PickleStepMessage{ast_node_ids: ids} = m, %TableRowMessage{} = row),
    do: %{m | ast_node_ids: ids ++ [row.id]}

  defp add_datatable(%PickleStepMessage{} = m, %StepMessage{argument: nil}), do: m

  defp add_datatable(%PickleStepMessage{} = m, %StepMessage{argument: {:datatable, d}} = s) do
    IEx.pry()
  end

  defp add_doc_string(%PickleStepMessage{} = m, %StepMessage{argument: nil}), do: m

  defp add_doc_string(%PickleStepMessage{} = m, %StepMessage{argument: {:doc_string, d}} = s) do
    IEx.pry()
  end

  defp get_id_and_update_compiler_acc(%@me{id_gen: gen} = compiler_acc) do
    {id, updated_generator} = ExGherkin.IdGenerator.get_id(gen)
    updated_acc = %{compiler_acc | id_gen: updated_generator}
    {id, updated_acc}
  end
end
