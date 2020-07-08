defmodule ExGherkin.TokenMatcher.TagLineParser do
  @constants %{
    tag: "@",
    comment: "#",
    title_keyword_sep: ":",
    table_cell: "|",
    docstring_sep: "\"\"\"",
    docstring_alt_sep: "```"
  }

  alias ExGherkin.{Line, Token}

  def parse(TagLine, %Line{content: c} = l, context) do
    raw_tags_line =
      case String.split(c, "\s#{@constants.comment}", parts: 2) do
        [tags, _possible_comments] -> tags
        [raw_tags_line] -> raw_tags_line
      end

    %{tags: unfiltered_tags} =
      raw_tags_line
      |> String.split("@")
      |> Enum.reduce(%{tags: [], column: 0}, fn string, acc ->
        case String.trim(string) do
          "" ->
            %{acc | column: acc.column + String.length(string)}

          trimmed_str ->
            clean_string = "@" <> trimmed_str
            new_token = %{content: clean_string, column: acc.column + 1}
            %{acc | tags: [new_token | acc.tags], column: acc.column + String.length(string) + 1}
        end
      end)

    unfiltered_tags = Enum.sort_by(unfiltered_tags, & &1.column)

    # TODO: do a filter for invalid tags with spaces
    %{column: new_indent} = unfiltered_tags |> Enum.min_by(& &1.column)

    new_token =
      struct!(Token, line: l, indent: new_indent, matched_type: TagLine, items: unfiltered_tags)

    ExGherkin.TokenMatcher.finalize_parse(context, new_token)
  end
end
