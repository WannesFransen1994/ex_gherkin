defmodule MMwriter do
  require IEx

  defp unstruct(%{__struct__: _} = map, acc) when is_map(map) do
    map |> Map.from_struct() |> unstruct(acc)
  end

  defp unstruct(%{__uf__: _} = map, acc) when is_map(map) do
    map |> Map.delete(:__uf__) |> unstruct(acc)
  end

  defp unstruct(map, acc) when is_map(map) do
    Enum.reduce(map, acc, fn
      :ignore, acc ->
        acc

      {_k, nil}, acc ->
        acc

      {_k, ""}, acc ->
        acc

      {_k, :ignore}, acc ->
        acc

      {_k, []}, acc ->
        acc

      {_k, {new_key, v}}, acc when is_map(v) or is_list(v) ->
        Map.put(acc, lower_camelcase(new_key), unstruct(v, %{}))

      {k, v}, acc when is_map(v) or is_list(v) ->
        Map.put(acc, lower_camelcase(k), unstruct(v, %{}))

      {k, data}, acc ->
        Map.put(acc, lower_camelcase(k), unstruct(data, %{}))
    end)
  end

  defp unstruct([], %{}) do
    :ignore
  end

  defp unstruct(list, acc) when is_list(list) do
    list
    |> Enum.map(fn
      %CucumberMessages.GherkinDocument.Feature.FeatureChild{} = el -> el.value
      # %CucumberMessages.GherkinDocument.Feature.Step{argument: {k,v}} = el -> el |> Map.put(k, v) |> Map.delete(:argument)
      other_el -> other_el
    end)
    |> Enum.reduce(acc, fn
      {_new_key, nil}, acc ->
        acc

      {new_key, value}, acc when is_map(acc) ->
        # Map.put(acc, lower_camelcase(new_key), unstruct(value, %{}))
        [Map.put(acc, lower_camelcase(new_key), unstruct(value, %{}))]

      {new_key, value}, acc when is_list(acc) ->
        unstructed = unstruct(value, %{})

        case unstructed do
          :ignore -> acc
          _ -> acc ++ [Map.put(%{}, lower_camelcase(new_key), unstructed)]
        end

      map, acc when is_map(acc) and acc == %{} ->
        unstructed = unstruct(map, %{})

        case unstructed do
          :ignore -> acc
          _ -> [unstruct(map, %{})]
        end

      map, acc ->
        unstructed = unstruct(map, %{})

        case unstructed do
          :ignore -> acc
          _ -> acc ++ [unstruct(map, %{})]
        end
    end)
  end

  defp unstruct({k, v}, acc) when not is_tuple(v),
    do: Map.put(acc, lower_camelcase(k), unstruct(v, %{}))

  defp unstruct(just_data, _acc) when not is_tuple(just_data), do: just_data

  alias(CucumberMessages.Envelope)

  def envelope_to_ndjson!(%Envelope{message: %{__struct__: message_type}} = message) do
    %{"name" => name} = Regex.named_captures(~r/(?<name>[^.]*)$/, Atom.to_string(message_type))

    jsonable = unstruct(message, %{})
    unclean_jsonable = Map.put_new(jsonable, lower_camelcase(name), jsonable["message"])
    Map.delete(unclean_jsonable, "message")
  end

  defp lower_camelcase(atom) when is_atom(atom), do: atom |> Atom.to_string() |> lower_camelcase()

  defp lower_camelcase(string) when is_binary(string) do
    {to_be_downcased, camelcased} = string |> Macro.camelize() |> String.split_at(1)
    String.downcase(to_be_downcased) <> camelcased
  end
end
