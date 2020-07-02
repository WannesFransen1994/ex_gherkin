defmodule ExGherkin do
  require Logger

  def tokenize(feature_file) do
    feature_file
    |> parse()
    |> ExGherkin.TokenWriter.write_tokens()
  end

  def parse(feature_file) do
    feature_file
    |> File.read!()
    |> String.split(~r/\R/)
    |> ExGherkin.Parser.parse()
  end

  def list_good_testdata() do
    # [File.cwd!(), "testdata", "good", "background.feature"]                     # OK
    # [File.cwd!(), "testdata", "good", "tags.feature"]                           # OK
    # [File.cwd!(), "testdata", "good", "complex_background.feature"]             # OK
    # [File.cwd!(), "testdata", "good", "example_token_multiple.feature"]         # OK
    # [File.cwd!(), "testdata", "good", "minimal.feature"]                        # OK
    # [File.cwd!(), "testdata", "good", "datatables.feature"]                     # OK
    # [File.cwd!(), "testdata", "good", "datatables_with_new_lines.feature"]      # OK
    # [File.cwd!(), "testdata", "good", "escaped_pipes.feature"]                  # OK
    # [File.cwd!(), "testdata", "good", "docstrings.feature"]                     # OK
    # [File.cwd!(), "testdata", "good", "i18n_fr.feature"]                        # OK
    # [File.cwd!(), "testdata", "good", "incomplete_background_1.feature"]        # OK
    # [File.cwd!(), "testdata", "good", "padded_example.feature"]
    [File.cwd!(), "testdata", "good", "spaces_in_language.feature"]
    |> Path.join()
    |> Path.wildcard()
  end

  def run_only_during_dev() do
    execute_good_test_files(list_good_testdata(), nil)
  end

  def execute_good_test_files([], latest_outcome), do: latest_outcome
  # def execute_good_test_files([], _latest_outcome), do: :ok

  def execute_good_test_files([file | rem], _latest_outcome) do
    result =
      file
      |> File.read!()
      |> print_filepath_and_return(file)
      |> print_and_return()
      |> String.split(~r/\R/)
      |> ExGherkin.Parser.parse()
      |> ExGherkin.TokenWriter.write_tokens()

    require Logger
    Logger.debug("\n" <> result)
    File.write!("DIFF_ME", result)

    execute_good_test_files(rem, result)
  end

  defp print_and_return(data) do
    Logger.debug("\n###################################\n" <> data <> "\n\n")
    data
  end

  defp print_filepath_and_return(data, path) do
    Logger.debug("\n#{path}\n")
    data
  end
end
