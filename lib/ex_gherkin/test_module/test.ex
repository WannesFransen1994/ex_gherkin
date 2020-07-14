defmodule MM.Writer do
  require IEx

  defp unstruct(%{__struct__: _} = map) do
    map
    |> Map.from_struct()
    |> unstruct()
  end

  defp unstruct(%{} = map) do
    Enum.reduce(map, [], fn v, acc ->
      case unstruct(v) do
        nil -> acc
        new_v -> [new_v | acc]
      end
    end)
    |> Enum.reverse()
    |> Enum.reduce(fn x, y ->
      Map.merge(x, y, fn _k, v1, v2 -> v2 ++ v1 end)
    end)
  end

  defp unstruct(list) when is_list(list) do
    Enum.map(list, fn el ->
      unstruct(el)
    end)
  end

  defp unstruct({key, value}) do
    case key do
      :__uf__ ->
        nil

      :message ->
        %{:source => unstruct(value)}

      :value ->
        unstruct(value)

      _ ->
        %{key => unstruct(value)}
    end
  end

  defp unstruct({:__uf__, value}), do: nil
    case key do
      :__uf__ ->
        nil

      :message ->
        %{:source => unstruct(value)}

      :value ->
        unstruct(value)

      _ ->
        %{key => unstruct(value)}
    end
  end

  defp unstruct(data) do
    case data do
      nil -> nil
      "" -> nil
      data -> data
    end
  end

  @spec envelopes_to_ndjson!(nonempty_maybe_improper_list) :: binary
  def envelopes_to_ndjson!(list_of_envelopes) when is_list(list_of_envelopes) do
    temp = list_of_envelopes
    |> Enum.map(&(&1 |> unstruct |> Jason.encode!()))
    |> Enum.join("\n")
     File.write!("ME", temp)
  end
end
