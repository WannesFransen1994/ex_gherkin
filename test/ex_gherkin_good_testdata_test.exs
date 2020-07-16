defmodule ExGherkinGoodTestdataTest do
  use ExUnit.Case
  require Logger

  @moduletag timeout: :infinity

  @files ["testdata", "good", "*.feature"]
         |> Path.join()
         |> Path.wildcard()

  @tag :good
  test "TOKENS: compare all testdata" do
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

  @tag :good
  test "SOURCE: compare all testdata" do
    opts = ["--no-pickles", "--predictable-ids", "--no-ast"]

    Enum.each(@files, fn file ->
      Logger.info("SOURCE:\tTesting the file: #{file}")

      result =
        ExGherkin.gherkin_from_path(file, opts)
        |> ExGherkin.print_messages("ndjson")

      correct_result = File.read!(file <> ".source.ndjson")
      # File.write!("diff/SOURCE_DIFF_ME", result)
      # File.write!("diff/SOURCE_DIFF_ME_RESULT", correct_result)
      assert result == correct_result
    end)
  end

  @tag :good
  test "AST: compare all testdata" do
    opts = ["--no-pickles", "--predictable-ids", "--no-source"]

    Enum.each(@files, fn file ->
      Logger.info("AST:\tTesting the file: #{file}")

      result =
        ExGherkin.gherkin_from_path(file, opts)
        |> ExGherkin.print_messages("ndjson")

      correct_result = File.read!(file <> ".ast.ndjson")
      # File.write!("diff/AST_DIFF_ME", result)
      # File.write!("diff/AST_DIFF_ME_RESULT", correct_result)
      assert result == correct_result
    end)
  end
end
