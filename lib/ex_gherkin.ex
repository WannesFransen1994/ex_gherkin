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
    [File.cwd!(), "testdata", "good", "docstrings.feature"]
    |> Path.join()
    |> Path.wildcard()
  end

  def run_only_during_dev() do
    # :debugger.start()
    # :int.ni(ExGherkin.Parser)
    # :int.break(ExGherkin.Parser, 93)
    # :int.break(ExGherkin.Parser, 105)
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

  # Just writing some gibberish which i think is from the java implementation
  def pr(opts \\ []),
    do:
      [Path.join([File.cwd!(), "testdata", "good", "minimal-example.feature"])]
      |> gherkin_from_paths(opts)

  def gherkin_from_paths(paths, opts) when is_list(paths) do
    # this normally gives a stream back of envelopes, we'll create the envelopes beforehand
    Enum.map(paths, fn p ->
      {:ok, envelope_w_source} = create_source_envelope(p, opts)
      require IEx
      IEx.pry()
      # envelopeFromPath is the func called in Gherkin.java

      # After which you call a parsermessagestream func with 1 envelope argument.
      #   This envelope has a source message which contains the data that can be parsed.
      parse_messages(envelope_w_source, opts)
    end)
  end

  # def print_messages(envelopes, "protobuf" = format) do
  # end

  # def print_messages(envelopes, "ndjson" = format) do
  # end

  alias CucumberMessages.{Envelope, Source, GherkinDocument}
  alias ExGherkin.{Parser, ParserContext}

  def create_source_envelope(path, _opts) do
    # create new envelope w source message inside. This message should contain the necessary data.
    case File.read(path) do
      {:ok, binary} ->
        hardcoded_mtype = "text/x.cucumber.gherkin+plain"
        source_message = %Source{data: binary, uri: path, media_type: hardcoded_mtype}
        source_envelope = %Envelope{message: source_message}
        {:ok, source_envelope}

      {:error, message} ->
        {:error, "Could not read file. Got: #{message}"}
    end
  end

  def parse_messages(%Envelope{message: message} = envelope, opts) do
    # Based on the include_source flag, this envelope is added to the messages list.
    #
    # If the envelope has a source, do following things
    #   FIRST CHALLENGE: Create the gherkinDocument variable.
    #   this has the complete AST already inside of it? nested messages? just how?

    # returns a list of envelopes/messages?

    meta_info = %{messages: [], gherkin_doc: nil}

    meta_info
    |> add_source_envelope(envelope, opts)
    |> add_gherkin_doc_envelope(message, opts)
    |> add_pickles_envelopes(nil, opts)
  end

  defp add_source_envelope(%{messages: m} = meta, envelope, opts) when is_list(opts) do
    case "--no-source" in opts do
      true -> meta
      false -> %{meta | messages: [envelope | m]}
    end
  end

  defp add_gherkin_doc_envelope(%{messages: m} = meta, %Source{data: d, uri: _u}, opts) do
    with {:has_no_ast_opt?, false} <- {:has_no_ast_opt?, "--no-ast" in opts},
         {:gherkin_doc_present?, false} <- {:gherkin_doc_present?, meta.gherkin_doc != nil},
         {:parser_context, %ParserContext{} = pc} <- {:parser_context, Parser.parse(d)},
         {:parseable?, {:ok, gherkin_doc}} <- {:parseable?, gherkin_doc_from_parsercontext(pc)} do
      %{meta | gherkin_doc: gherkin_doc, messages: [%Envelope{message: gherkin_doc} | m]}
    else
      {:has_no_ast_opt?, true} ->
        Logger.warn("no ast opt")
        meta

      {:gherkin_doc_present?, true} ->
        gherkin_doc_envelope = %Envelope{message: meta.gherkin_doc}
        %{meta | messages: [gherkin_doc_envelope | m]}
    end
  end

  defp gherkin_doc_from_parsercontext(_parsercontext) do
    # TODO
    {:ok, %GherkinDocument{}}
  end

  defp add_pickles_envelopes(meta, _smthing, _opts) do
    # TODO
    meta
  end
end
