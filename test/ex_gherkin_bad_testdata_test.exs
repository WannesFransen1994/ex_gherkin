defmodule ExGherkinBadTestdataTest do
  use ExUnit.Case
  require Logger

  @moduletag timeout: :infinity

  @files ["testdata", "bad", "*.feature"]
         |> Path.join()
         |> Path.wildcard()

  @tag :bad
  test "BAD: compare all bad testdata" do
    opts = ["--no-source", "--no-pickles", "--predictable-ids"]

    Enum.each(@files, fn file ->
      Logger.info("BAD:\tTesting the file: #{file}")

      result =
        ExGherkin.gherkin_from_path(file, opts)
        |> ExGherkin.print_messages("ndjson")

      correct_result = File.read!(file <> ".errors.ndjson")
      File.write!("diff/ERR_DIFF_ME", result)
      File.write!("diff/ERR_DIFF_ME_RESULT", correct_result)
      assert result == correct_result
    end)
  end
end
