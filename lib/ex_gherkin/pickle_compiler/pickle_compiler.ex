defmodule ExGherkin.PickleCompiler do
  defstruct id_gen: nil, pickles: []

  # alias CucumberMessages.GherkinDocument
  require IEx

  def compile(%ExGherkin.AstBuilder{} = id_generator) do
    me = %__MODULE__{id_gen: id_generator}
    IEx.pry()
  end
end
