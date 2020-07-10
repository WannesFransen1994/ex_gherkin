defmodule ExGherkin.Token do
  @me __MODULE__
  alias CucumberMessages.Location

  defstruct [
    :line,
    :matched_type,
    :matched_keyword,
    :matched_text,
    :items,
    indent: 1
  ]

  def get_location(%@me{line: l, indent: i}), do: %Location{column: i, line: l.index}
end

defmodule ExGherkin.Line do
  @enforce_keys [:content, :index]
  defstruct [:content, :index]
end
