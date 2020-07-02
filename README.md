# ExGherkin

* install elixir
* clone this repo
* mix deps.get
* mix test

Or you can test manually
```
$ iex --werl -S mix run # starts an interactive shell
iex> "testdata/good/very_long.feature" |> ExGherkin.tokenize |> IO.puts
iex> parser_context = "testdata/good/very_long.feature" |> ExGherkin.parse
iex> parser_context.errors
[]
iex> parser_context.tokens
.... a lot of data
iex> Map.keys parser_context
[:__struct__, :docstring_indent, :docstring_sep, :errors, :language, :lexicon,
 :lines, :reverse_queue, :smthing_with_ast_builder?, :state, :tokens]
```
Note: above output is not guaranteed after some updates. This is just to illustrate the usage.

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_gherkin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_gherkin, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_gherkin](https://hexdocs.pm/ex_gherkin).

## Extra info

testdata from cucumber gherkin monorepo commit hash 27e0b8a7d9102b83f7f2100cd85f46ef211133a4
