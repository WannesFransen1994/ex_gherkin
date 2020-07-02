defmodule ExGherkin.TokenMatcher do
  @constants %{
    tag: "@",
    comment: "#",
    title_keyword_sep: ":",
    table_cell: "|",
    docstring_sep: "\"\"\"",
    docstring_alt_sep: "```"
  }

  @language_regex ~r/^\s*#\s*language\s*:\s*(?<lang>[a-zA-Z\-_]+)\s*$/

  require IEx
  alias ExGherkin.{Token, ParserContext, Line}
  alias ExGherkin.Gherkin.Lexicon

  # ############# #
  # Match section #
  # ############# #

  def match?(EOF, %Line{content: ""}, %ParserContext{lines: []}), do: true
  def match?(EOF, %Line{}, _context), do: false
  def match?(Empty, %Line{content: c}, _), do: c |> String.trim() |> match_empty()
  def match?(Comment, %Line{content: c}, _), do: my_starts_with?(c, @constants.comment)
  def match?(TagLine, %Line{content: c}, _), do: my_starts_with?(c, @constants.tag)
  def match?(TableRow, %Line{content: c}, _), do: my_starts_with?(c, @constants.table_cell)

  def match?(DocStringSeparator, string, _context), do: false

  def match?(Language, %Line{content: c}, _context), do: Regex.match?(@language_regex, c)
  def match?(Other, %Line{}, _context), do: true

  def match?(type, %Line{content: c}, %ParserContext{lexicon: lex})
      when type in [FeatureLine, RuleLine, BackgroundLine, StepLine, ExamplesLine, ScenarioLine] do
    Lexicon.load_keywords(type, lex) |> match_line(type, c) || false
  end

  # def match?(ScenarioLine, %Line{content: c}, %ParserContext{lexicon: lex}) do
  #   a = match_scenario?(lex, c)
  #   b = match_scenario_outline?(lex, c)
  #   a || b || false
  # end

  # ############## #
  # Helper section #
  # ############## #

  # defp match_scenario?(lex, string),
  #   do: Lexicon.load_keywords(ScenarioLine, lex) |> match_line(ScenarioLine, string)

  # defp match_scenario_outline?(lex, string),
  #   do: Lexicon.load_keywords(ScenarioOutLine, lex) |> match_line(ScenarioLine, string)

  defp match_line(keywords, type, string)
       when type in [FeatureLine, RuleLine, BackgroundLine, ExamplesLine, ScenarioLine] do
    keywords
    |> Enum.map(&"#{&1}#{@constants.title_keyword_sep}")
    |> Enum.find(&(string |> String.trim() |> String.starts_with?(&1)))
  end

  defp match_line(keywords, StepLine, string),
    do: Enum.find(keywords, &(string |> String.trim() |> String.starts_with?(&1)))

  defp base_title_regex(key), do: ~r/(?<indent>\s*)#{key}\s*(?<matched_text>.*)/
  defp base_key_regex(key), do: ~r/(?<indent>\s*)#{key}(?<matched_text>.*)/

  defp match_empty(""), do: true
  defp match_empty(_str), do: false

  defp my_starts_with?(text, prefix) do
    text |> String.trim() |> String.starts_with?(prefix)
  end

  # ############# #
  # Parse section #
  # ############# #

  def parse(type, %Line{} = l, context) when type in [EOF, Empty] do
    token = struct!(Token, line: l, matched_type: type)
    %{context | reverse_queue: [token | context.reverse_queue]}
  end

  def parse(Comment, %Line{} = l, context) do
    token = struct!(Token, line: l, matched_type: Comment, matched_text: l.content)
    %{context | reverse_queue: [token | context.reverse_queue]}
  end

  def parse(TagLine, l, context), do: __MODULE__.TagLineParser.parse(TagLine, l, context)

  def parse(TableRow, l, context), do: __MODULE__.TableRowParser.parse(TableRow, l, context)

  def parse(type, %Line{content: c} = l, %ParserContext{lexicon: lex} = context)
      when type in [FeatureLine, BackgroundLine, RuleLine, ExamplesLine, ScenarioLine] do
    keyword_w_sep = Lexicon.load_keywords(type, lex) |> match_line(type, c)
    keyword = String.trim_trailing(keyword_w_sep, @constants.title_keyword_sep)

    %{"indent" => indent, "matched_text" => matched_text} =
      base_title_regex(keyword_w_sep) |> Regex.named_captures(c)

    opts = [
      matched_type: type,
      line: l,
      indent: String.length(indent) + 1,
      matched_text: matched_text,
      matched_keyword: keyword
    ]

    token = struct!(Token, opts)
    %{context | reverse_queue: [token | context.reverse_queue]}
  end

  def parse(StepLine, %Line{content: c} = l, context) do
    keyword = Lexicon.load_keywords(StepLine, context.lexicon) |> match_line(StepLine, c)

    %{"indent" => indent, "matched_text" => matched_text} =
      keyword |> base_key_regex() |> Regex.named_captures(c)

    opts = [
      matched_type: StepLine,
      line: l,
      indent: String.length(indent) + 1,
      matched_text: matched_text,
      matched_keyword: keyword
    ]

    token = struct!(Token, opts)
    %{context | reverse_queue: [token | context.reverse_queue]}
  end

  def parse(DocStringSeparator, %Line{content: c} = l, context) do
    raise "DocStringSeparator implement me"
  end

  def parse(Language, %Line{content: c} = l, context) do
    raise "load different lexicon"
    %{"lang" => lang} = Regex.named_captures(@language_regex, c)
    token = struct!(Token, line: l, matched_type: Language, matched_text: lang)
    %{context | reverse_queue: [token | context.reverse_queue]}
  end

  def parse(Other, %Line{content: c} = l, context) do
    token = struct!(Token, line: l, matched_type: Other, matched_text: c)
    %{context | reverse_queue: [token | context.reverse_queue]}
  end
end
