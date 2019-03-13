ExUnit.start()

# Declares explicitly because order is important
requires = ~w(
  locker.exs
  locker_ext.exs
  locker_schema.exs
  locker_ext_schema.exs
)

Enum.each(requires, fn req ->
  path = Path.join([".", "support", req])
  Code.require_file(path, __DIR__)
end)
