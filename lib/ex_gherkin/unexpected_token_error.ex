defmodule ExGherkin.UnexpectedTokenError do
  # @allowed_types [UnexpectedEOF, UnexpectedToken]
  defstruct [:type, :line, :expected_tokens, :comment]
end
