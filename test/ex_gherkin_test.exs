defmodule ExGherkinTest do
  use ExUnit.Case
  doctest ExGherkin
  require Logger

  # test "compare all testdata" do
  #   files =
  #     [File.cwd!(), "testdata", "good", "*.feature"]
  #     |> Path.join()
  #     |> Path.wildcard()

  #   Enum.each(files, fn path ->
  #     correct_output = File.read!(path <> ".tokens")
  #     tokenized_output = ExGherkin.tokenize(path)
  #     result = correct_output == tokenized_output

  #     if result == false do
  #       Logger.warn("File #{path} is not being parsed correctly.")
  #     end

  #     assert result
  #   end)
  # end

  @file_name = "testdata/good/minimal.feature"

  test "sampletest source correctly structured" do
    opts = ["--no-pickles", "--predictable-ids", "--no-ast"]

    result =
      ExGherkin.gherkin_from_path(@file_name, opts)
      |> ExGherkin.print_messages("ndjson")
      |> Enum.map(&Jason.encode!(&1))
      |> Enum.join("\n")

    result = result <> "\n"

    decent_result = File.read!(path <> ".source.ndjson")
    File.write!("diff/DIFF_ME", result)
    File.write!("diff/DIFF_ME_RESULT", decent_result)
    assert result == decent_result
  end

  test "sampletest ast correctly structured" do
    opts = ["--no-pickles", "--predictable-ids", "--no-source"]

    result =
      ExGherkin.gherkin_from_path(@file_name, opts)
      |> ExGherkin.print_messages("ndjson")
      |> Enum.map(&Jason.encode!(&1))
      |> Enum.join("\n")

    result = result <> "\n"

    decent_result = File.read!(path <> ".ast.ndjson")
    File.write!("diff/AST_DIFF_ME", result)
    File.write!("diff/AST_DIFF_ME_RESULT", decent_result)
    assert result == decent_result
  end
end
