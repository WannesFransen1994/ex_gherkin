defmodule ExGherkin do
  require Logger

  def tokenize(feature_file) do
    feature_file
    |> parse()
    |> ExGherkin.TokenWriter.write_tokens()
  end

  def parse(feature_file, opts \\ []),
    do: feature_file |> File.read!() |> ExGherkin.Parser.parse(opts)

  def pr(opts \\ ["--no-pickles", "--predictable-ids"]) do
    Path.join(["testdata", "good", "minimal-example.feature"])
    |> gherkin_from_path(opts)
  end

  def gherkin_from_paths(paths, opts) when is_list(paths) do
    Enum.map(paths, &gherkin_from_path(&1, opts))
  end

  def gherkin_from_path(path, opts) when is_binary(path) do
    {:ok, envelope_w_source} = create_source_envelope(path, opts)

    envelope_w_source
    |> parse_messages(opts)

    # |> print_messages("ndjson")
  end

  # def print_messages(envelopes, "protobuf" = format) do
  # end

  def print_messages(envelopes, "ndjson" = _format) do
    Enum.map(envelopes, &MMwriter.envelope_to_ndjson!/1)
  end

  alias CucumberMessages.{Envelope, Source}
  alias ExGherkin.{Parser, ParserContext}

  def create_source_envelope(path, _opts) do
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
    meta_info = %{messages: [], gherkin_doc: nil}

    meta_info
    |> add_source_envelope(envelope, opts)
    |> add_gherkin_doc_envelope(message, opts)
    |> add_pickles_envelopes(nil, opts)
    |> Map.fetch!(:messages)
    |> Enum.reverse()
  end

  defp add_source_envelope(%{messages: m} = meta, envelope, opts) when is_list(opts) do
    case "--no-source" in opts do
      true -> meta
      false -> %{meta | messages: [envelope | m]}
    end
  end

  defp add_gherkin_doc_envelope(%{messages: m} = meta, %Source{data: d, uri: u}, opts) do
    with {:has_no_ast_opt?, false} <- {:has_no_ast_opt?, "--no-ast" in opts},
         {:gherkin_doc_present?, false} <- {:gherkin_doc_present?, meta.gherkin_doc != nil},
         {:parser_context, %ParserContext{} = pc} <- {:parser_context, Parser.parse(d, opts)},
         {:parseable?, {:ok, gherkin_doc}} <- {:parseable?, gherkin_doc_from_parsercontext(pc)} do
      new_gherkin_doc = %{gherkin_doc | uri: u}
      %{meta | gherkin_doc: new_gherkin_doc, messages: [%Envelope{message: new_gherkin_doc} | m]}
    else
      {:has_no_ast_opt?, true} ->
        Logger.warn("no ast opt")
        meta

      {:gherkin_doc_present?, true} ->
        gherkin_doc_envelope = %Envelope{message: meta.gherkin_doc}
        %{meta | messages: [gherkin_doc_envelope | m]}
    end
  end

  defp gherkin_doc_from_parsercontext(%ParserContext{ast_builder: b}), do: {:ok, b.gherkin_doc}

  defp add_pickles_envelopes(meta, _smthing, opts) do
    case "--no-pickles" in opts do
      true ->
        meta

      false ->
        require IEx
        IEx.pry()
    end
  end
end
