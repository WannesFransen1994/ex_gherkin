defmodule MMwriter do
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

      {k, v}, acc when is_map(v) or is_list(v) ->
        Map.put(acc, lower_camelcase(k), unstruct(v, %{}))

      {k, data}, acc ->
        Map.put(acc, lower_camelcase(k), data)
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
        # Map.put(acc, lower_camelcase(new_key), unstruct(value, %{}))
        [Map.put(acc, lower_camelcase(new_key), unstruct(value, %{}))]

      {new_key, value}, acc when is_list(acc) ->
        acc ++ [Map.put(%{}, lower_camelcase(new_key), unstruct(value, %{}))]

      map, acc when is_map(acc) and acc == %{} ->
        [unstruct(map, %{})]

      map, acc ->
        acc ++ [unstruct(map, %{})]
    end)
  end

  alias CucumberMessages.Envelope

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
