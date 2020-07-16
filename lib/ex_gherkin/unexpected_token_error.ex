defprotocol ExGherkin.ParserException do
  def get_message(error)
  def generate_message(error)
  def get_location(error)
end

defmodule ExGherkin.UnexpectedTokenError do
  # @allowed_types [UnexpectedEOF, UnexpectedToken]
  defstruct [:type, :line, :expected_tokens, :comment]
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
