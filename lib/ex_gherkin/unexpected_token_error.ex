defprotocol ExGherkin.ParserException do
  def get_message(error)
  def generate_message(error)
  def get_location(error)
end

defmodule ExGherkin.UnexpectedTokenError do
  defstruct [:line, :expected_tokens, :comment]

  defimpl ExGherkin.ParserException do
    def get_message(%{} = me) do
      location = struct!(ExGherkin.Token, line: me.line) |> ExGherkin.Token.get_location()
      expected_string = Enum.join(me.expected_tokens, ", ")
      base = "(#{location.line}:#{location.column}): "
      base <> "expected: #{expected_string}, got '#{me.line.content}'"
    end

    def generate_message(%{} = error), do: %{error | message: get_message(error)}

    def get_location(%{} = me),
      do: struct!(ExGherkin.Token, line: me.line) |> ExGherkin.Token.get_location()
  end
end

defmodule ExGherkin.UnexpectedEOFError do
  defstruct [:line, :expected_tokens, :comment]

  defimpl ExGherkin.ParserException do
    def get_message(%{} = me) do
      location = struct!(ExGherkin.Token, line: me.line) |> ExGherkin.Token.get_location()

      expected_string = Enum.join(me.expected_tokens, ", ")
      base = "(#{location.line}:0): "
      base <> "unexpected end of file, expected: #{expected_string}"
    end

    def generate_message(%{} = error), do: %{error | message: get_message(error)}

    def get_location(%{} = me),
      do:
        struct!(ExGherkin.Token, line: me.line)
        |> ExGherkin.Token.get_location()
        |> Map.put(:column, nil)
  end
end

defmodule ExGherkin.AstBuilderError do
  defstruct [:message, :location]

  defimpl ExGherkin.ParserException do
    def get_message(%{location: l}),
      do: "(#{l.line}:#{l.column}): inconsistent cell count within the table"

    def generate_message(%{} = error), do: %{error | message: get_message(error)}
    def get_location(%{location: l}), do: l
  end
end

defmodule ExGherkin.NoSuchLanguageError do
  defstruct [:language, :location]

  defimpl ExGherkin.ParserException do
    def get_message(%{language: lang, location: l}),
      do: "(#{l.line}:#{l.column}): Language not supported: #{lang}"

    def generate_message(%{} = error), do: %{error | message: get_message(error)}
    def get_location(%{location: l}), do: l
  end
end
