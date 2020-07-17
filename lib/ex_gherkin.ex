defmodule ExGherkin do
  require Logger
  require IEx

  alias CucumberMessages.{Envelope, Source}
  alias ExGherkin.{Parser, ParserContext, TokenWriter}

  def tokenize(feature_file, opts \\ []) do
    feature_file
    |> File.read!()
    |> Parser.parse(opts)
    |> TokenWriter.write_tokens()
  end

  def parse_paths(paths, opts) when is_list(paths), do: Enum.map(paths, &parse_path(&1, opts))

  def parse_path(path, opts) when is_binary(path) do
    {:ok, envelope_w_source} = create_source_envelope(path, opts)
    format = opts[:format] || :ndjson

    envelope_w_source
    |> parse_messages(opts)
    |> print_messages(format)
  end

  def print_messages(envelopes, :ndjson) do
    result =
      Enum.map(envelopes, &MMwriter.envelope_to_ndjson!/1)
      |> Enum.map(&Jason.encode!(&1))
      |> Enum.join("\n")

    result <> "\n"
  end

  # def print_messages(envelopes, "protobuf" = format) do
  # end

  defp create_source_envelope(path, _opts) do
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

  defp parse_messages(%Envelope{message: %Source{} = s} = envelope, opts) do
    %{messages: [], parsable?: true, source: s, ast_builder: nil}
    |> add_source_envelope(envelope, opts)
    |> add_gherkin_doc_envelope(opts)
    |> add_pickles_envelopes(nil, opts)
    |> Map.fetch!(:messages)
    |> Enum.reverse()
  end

  defp add_source_envelope(%{messages: m} = meta, envelope, opts) when is_list(opts) do
    case :no_source in opts do
      true -> meta
      false -> %{meta | messages: [envelope | m]}
    end
  end

  defp add_gherkin_doc_envelope(%{source: source} = meta, opts) do
    case :no_ast in opts and :no_pickles in opts do
      true ->
        meta

      false ->
        Parser.parse(source.data, opts)
        |> get_ast_builder(source.uri)
        |> update_meta(meta, :ast_builder)
    end
  end

  defp get_ast_builder(%ParserContext{errors: []} = pc, _uri), do: {:ok, pc.ast_builder}

  defp get_ast_builder(%ParserContext{errors: errors}, uri) do
    result =
      Enum.map(errors, fn error ->
        message = ExGherkin.ParserException.get_message(error)
        location = ExGherkin.ParserException.get_location(error)
        source_ref = %CucumberMessages.SourceReference{location: location, uri: uri}
        to_be_wrapped = %CucumberMessages.ParseError{message: message, source: source_ref}
        %Envelope{message: to_be_wrapped}
      end)

    {:error, result}
  end

  defp update_meta({:ok, ast_builder}, %{messages: m, source: s} = meta, :ast_builder) do
    new_ast_builder = %{ast_builder | gherkin_doc: %{ast_builder.gherkin_doc | uri: s.uri}}
    new_message = %Envelope{message: new_ast_builder.gherkin_doc}
    %{meta | ast_builder: new_ast_builder, messages: [new_message | m]}
  end

  defp update_meta({:error, messages}, %{messages: m} = meta, :ast_builder),
    do: %{meta | parsable?: false, messages: Enum.reduce(messages, m, &[&1 | &2])}

  defp add_pickles_envelopes(%{ast_builder: builder, parsable?: true} = meta, _smthing, opts) do
    case :no_pickles in opts do
      true ->
        meta

      false ->
        ExGherkin.PickleCompiler.compile(builder, meta.source.uri)
        IEx.pry()
    end
  end

  defp add_pickles_envelopes(%{parsable?: false} = meta, _smthing, _opts), do: meta
end
