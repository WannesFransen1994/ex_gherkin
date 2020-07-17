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
