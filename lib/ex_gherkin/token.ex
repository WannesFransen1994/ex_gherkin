defmodule ExGherkin.Token do
  defstruct [
    :line,
    :matched_type,
    :matched_keyword,
    :matched_text,
    :items,
    indent: 1
  ]
end

defmodule ExGherkin.Line do
  @enforce_keys [:content, :index]
  defstruct [:content, :index]
end
