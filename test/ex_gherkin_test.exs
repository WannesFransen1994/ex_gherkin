defmodule ExGherkinTest do
  use ExUnit.Case
  doctest ExGherkin
  require Logger

  @moduletag timeout: :infinity

  @files ["testdata", "good", "descriptions.feature"]
         |> Path.join()
         |> Path.wildcard()

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

  test "sampletest source correctly structured" do
    opts = ["--no-pickles", "--predictable-ids", "--no-ast"]

    Enum.each(@files, fn file ->
      Logger.info("SOURCE:\tTesting the file: #{file}")

      result =
        ExGherkin.gherkin_from_path(file, opts)
        |> ExGherkin.print_messages("ndjson")

      correct_result = File.read!(file <> ".source.ndjson")
      File.write!("diff/SOURCE_DIFF_ME", result)
      File.write!("diff/SOURCE_DIFF_ME_RESULT", correct_result)
      assert result == correct_result
    end)
  end

  test "sampletest ast correctly structured" do
    opts = ["--no-pickles", "--predictable-ids", "--no-source"]

    Enum.each(@files, fn file ->
      Logger.info("AST:\tTesting the file: #{file}")

      result =
        ExGherkin.gherkin_from_path(file, opts)
        |> ExGherkin.print_messages("ndjson")

      correct_result = File.read!(file <> ".ast.ndjson")
      File.write!("diff/AST_DIFF_ME", result)
      File.write!("diff/AST_DIFF_ME_RESULT", correct_result)
      assert result == correct_result
    end)
  end
end
