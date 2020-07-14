defmodule MMwriter do
  defp unstruct(%{__struct__: _} = map, acc) when is_map(map) do
    map |> Map.from_struct() |> unstruct(acc)
  end

  defp unstruct(%{__uf__: _} = map, acc) when is_map(map) do
    map |> Map.delete(:__uf__) |> unstruct(acc)
  end

  defp unstruct(map, acc) when is_map(map) do
    Enum.reduce(map, acc, fn
      :ignore, acc -> acc
      {_k, nil}, acc -> acc
      {_k, ""}, acc -> acc
      {_k, :ignore}, acc -> acc
      {_k, []}, acc -> acc
      {k, v}, acc when is_map(v) or is_list(v) -> Map.put(acc, k, unstruct(v, %{}))
      {k, data}, acc -> Map.put(acc, k, data)
    end)
  end

  defp unstruct([], %{}), do: :ignore

  defp unstruct(list, acc) when is_list(list) do
    list
    |> Enum.map(fn
      %CucumberMessages.GherkinDocument.Feature.FeatureChild{} = el -> el.value
      other_el -> other_el
    end)
    |> Enum.reduce(acc, fn
      {_new_key, nil}, acc ->
        acc

      {new_key, value}, acc when is_map(acc) ->
        [Map.put(acc, new_key, unstruct(value, %{}))]

      {new_key, value}, acc when is_list(acc) ->
        acc ++ [Map.put(acc, new_key, unstruct(value, %{}))]

      map, acc when is_map(acc) and acc == %{} ->
        [unstruct(map, %{})]

      map, acc ->
        acc ++ [unstruct(map, %{})]
    end)
  end

  alias CucumberMessages.Envelope

  def envelope_to_ndjson!(%Envelope{} = message) do
    # :debugger.start()
    # :int.ni(MMwriter)
    # :int.break(MMwriter, 60)
    # :int.break(MMwriter, 57)
    # :int.break(MMwriter, 54)
    # :int.break(MMwriter, 50)
    # :int.break(MMwriter, 46)

    unstruct(message.message, %{})
  end
end

# recompile; t = ExGherkin.pr ; t |> Enum.at(1) |> MMwriter.envelope_to_ndjson!
# recompile; t |> Enum.at(1) |> MMwriter.envelope_to_ndjson!
