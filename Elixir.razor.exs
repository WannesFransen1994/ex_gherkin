#       This code was generated by Berp (http://https://github.com/gasparnagy/berp/).
#
#       Changes to this file may cause incorrect behavior and will be lost if
#       the code is regenerated.

@using Berp;
@helper CallProduction(ProductionRule production)
{
    switch(production.Type) {
        case ProductionRuleType.Start:
                @:AstBuilder.start_rule(@production.RuleName) |>
            break;
        case ProductionRuleType.End:
                @:AstBuilder.end_rule(@production.RuleName) |>
            break;
        case ProductionRuleType.Process:
                @*
                # What is the exact responsibility of this func? is the token added here?
                #   Don't put the token immediately in the list but do something else with it here?
                *@
                @:AstBuilder.build() |>
            break;
    }
}

@helper HandleParserError(IEnumerable<string> expectedTokens, State state){
  <text>
    state_comment = "State: @state.Id - @Raw(state.Comment)"
    expected_tokens = ["@Raw(string.Join("\", \"", expectedTokens))"]
    handle_error(context, line, expected_tokens, state_comment)
    @* # Just rome random comment to stop the elixir IDE linter from identifying as a string # " *@
  </text>
}

@helper matchToken(TokenType tokenType)
{<text>match_@(tokenType)(context, token)</text>}

defmodule ExGherkin.TokenTypes do
  @@token_types [
    None,
    @foreach(var rule in Model.RuleSet.TokenRules){
    <text>@rule.Name.Replace("#", ""),</text>
    }
  ]
  def get_ordinal(type), do: Enum.find_index @@token_types, &( &1 == type )
end

defmodule ExGherkin.RuleTypes do
  @@rule_types [
    None,
    @foreach(var rule in Model.RuleSet.Where(r => !r.TempRule)){
    <text>@rule.Name.Replace("#", ""),</text>
    }
  ]

  def get_ruletype_for_tokentype(type) do
    index = ExGherkin.TokenTypes.get_ordinal type
    Enum.at(@@rule_types, index)
  end
end



defmodule ExGherkin.ParserContext do
  @@enforce_keys [:lines, :lexicon]
  defstruct [
    :ast_builder,
    :lines,
    :current_token,
    language: "en",
    lexicon: nil,
    reverse_queue: [],
    errors: [],
    state: 0,
    tokens: [],
    docstring_sep: nil,
    docstring_indent: nil
  ]
end

defmodule ExGherkin.@Model.ParserClassName do
  alias ExGherkin.{ParserContext, TokenMatcher, Token, Line, AstBuilder}

  def parse(text, opts) when is_binary(text), do: text |> String.split(~r/\R/) |> parse(opts)

  def parse(lines, opts) when is_list(lines) do
    {:ok, default_lexicon} = ExGherkin.Gherkin.Lexicon.load_lang("en")

    lines_structs =
      Enum.with_index(lines, 1)
      |> Enum.map(fn {text, index} -> struct!(Line, content: text, index: index) end)

    struct!(ParserContext, lines: lines_structs, lexicon: default_lexicon, ast_builder: AstBuilder.new(opts))
    |> AstBuilder.start_rule( @Model.RuleSet.StartRule.Name )
    |> parse_recursive()
  end

  defp parse_recursive(%ParserContext{reverse_queue: [%Token{matched_type: EOF} | _]} = c) do
    ordened_tokens = Enum.reverse(c.reverse_queue)
    %{c | tokens: ordened_tokens, reverse_queue: []} |> AstBuilder.end_rule(@Model.RuleSet.StartRule.Name )
  end

  defp parse_recursive(%ParserContext{lines: [], reverse_queue: rt} = c) do
    eof_token = struct!(Token, line: nil, matched_type: EOF)
    new_context = %{c | reverse_queue: [eof_token | rt]}
    parse_recursive(new_context)
  end

  defp parse_recursive(%ParserContext{lines: [current_line | rem_lines]} = context) do
    new_context = %{context | lines: rem_lines}
    match_token(current_line, new_context) |> parse_recursive()
  end

  defp update_next_state(context, next) when is_integer(next), do: %{context | state: next}

@foreach(var state in Model.States.Values.Where(s => !s.IsEndState)){
<text>
  defp match_token(%Line{} = line, %ParserContext{state: @state.Id} = context) do
    cond do
      @foreach(var transition in state.Transitions){
          if (transition.LookAheadHint != null){
            <text>
              TokenMatcher.match?(@transition.TokenType , line, context) and (lookahead?(@transition.LookAheadHint.Id, line, context) |> Map.fetch!(:match?) == true) ->
            </text>
          } else {
            <text>TokenMatcher.match?(@transition.TokenType , line, context) -> </text>
          }
          <text>
              TokenMatcher.parse(@transition.TokenType , line, context) |>
          </text>
          foreach(var production in transition.Productions){ @CallProduction(production) }
          <text>
          update_next_state(@transition.TargetState)
          </text>
        }
      @* # Code below is basically called when no other token matches.  *@
      true -> @HandleParserError(state.Transitions.Select(t => "#" + t.TokenType.ToString()).Distinct(), state)
    end
  end
</text>
}

  # Will be called when theres an invalid state or unknown token in the code.
  defp match_token(line, context), do:
    raise "invalid state or unknown token. \n#{IO.inspect(line.content, label: LINE.CONTENT)}\n#{IO.inspect(context, label: CONTEXT)}"




  defp lookahead?(0, _line, %ParserContext{} = ctext) do
    expected_tokens = [ExamplesLine]
    skip_tokens = [Empty,Comment,TagLine]
    look_helper(expected_tokens, skip_tokens, %{context: ctext, match?: false, stop?: false})
  end

  defp look_helper(_expected, _skip, %{stop?: true} = acc), do: acc
  defp look_helper(_expected, _skip, %{match?: true} = acc), do: acc

  defp look_helper(expected, skip, %{context: %{lines: [nextl | rem]} = context} = acc) do
    updated_context = %{context | lines: rem}

    new_acc =
      case try_to_match_token_types(expected, nextl, updated_context) do
        {_new_context, true} ->
          %{acc | context: context, match?: true}

        {_new_context, false} ->
          case try_to_match_token_types(skip, nextl, updated_context) do
            {new_context, true} -> %{acc | context: new_context}
            {new_context, false} -> %{acc | context: new_context, stop?: true}
          end
      end

    look_helper(expected, skip, new_acc)
  end

  defp try_to_match_token_types(types, line, context) do
    case Enum.find(types, &TokenMatcher.match?(&1, line, context)) do
      nil -> {context, false}
      type -> {TokenMatcher.parse(type, line, context), true}
    end
  end


  defp handle_error(context, line, expected_tokens, state_comment) do
    general_opts = [line: line, expected_tokens: expected_tokens, comment: state_comment]
    error = case TokenMatcher.match?(EOF, line, context) do
      true -> struct!(ExGherkin.UnexpectedTokenError, [type: UnexpectedEOF] ++ general_opts)
      false -> struct!(ExGherkin.UnexpectedTokenError, [type: UnexpectedToken] ++ general_opts)
    end
    new_errors = [error | context.errors]
    %{context | errors: new_errors}
  end
end
