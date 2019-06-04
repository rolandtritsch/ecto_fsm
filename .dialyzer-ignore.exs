# .dialyzer_ignore.exs
[
  ~r/^:0:unknown_function Function Ecto\.FSM\.Machine\.State\.[A-Za-z]+\.__impl__\/1 does not exist\./,
  ~r/^:0:unknown_function Function Ecto\.FSM\.Schema\.State\.[A-Za-z]+\.__impl__\/1 does not exist\./
]
