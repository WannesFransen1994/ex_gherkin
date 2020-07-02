defmodule ExGherkinTest do
  use ExUnit.Case
  doctest ExGherkin
  require Logger

  test "compare all testdata" do
    files =
      [File.cwd!(), "testdata", "good", "*.feature"]
      |> Path.join()
      |> Path.wildcard()

    Enum.each(files, fn path ->
      correct_output = File.read!(path <> ".tokens")
      tokenized_output = ExGherkin.tokenize(path)
      result = correct_output == tokenized_output

      if result == false do
        Logger.warn("File #{path} is not being parsed correctly.")
      end

      assert result
    end)
  end
end
