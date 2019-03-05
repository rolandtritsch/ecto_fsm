defmodule Ecto.FSM.Schema do
  @moduledoc """
  Provides `status/{1,2}` macro for adding status field in an `Ecto.Schema`.
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.FSM.Schema

      @before_compile Ecto.FSM.Schema
    end
  end

  defmacro __before_compile__(env) do
    states_schema = env.module

    states_handler =
      states_schema
      |> Module.get_attribute(:states_handler)
      |> case do
        nil ->
          raise """
          Schema #{env.module} is missing a status field.

          You can add one with `Ecto.FSM.Schema.status/{1,2}`.
          """

        m ->
          m
      end

    states_field = Module.get_attribute(states_schema, :states_field)

    quote do
      alias Ecto.Changeset

      def state_name(s) do
        s
        |> Changeset.change()
        |> Changeset.fetch_field(unquote(states_field))
        |> case do
          {:data, v} -> v
          {:changes, v} -> v
          :error -> raise "Missing field: #{unquote(states_field)}"
        end
      end

      def set_state_name(s, name) do
        s
        |> Changeset.change()
        |> Changeset.put_change(unquote(states_field), name)
      end

      defimpl Ecto.FSM.Machine.State do
        def handlers(_), do: [unquote(states_handler)]

        def state_name(s), do: unquote(states_schema).state_name(s)

        def set_state_name(s, name), do: unquote(states_schema).set_state_name(s, name)
      end
    end
  end

  @doc """
  Generates `status` field from an `Ecto.FSM` module.

  ## Options

  * `:name` - the name of the field for status
  * `:type` - module name for the enumeration type (use `EctoEnum`)
  * `:default` - default value for status field
  """
  defmacro status(handler, opts \\ []) do
    opts =
      [name: :status, type: Module.concat(__CALLER__.module, "Status"), default: nil]
      |> Keyword.merge(opts)

    states_field = Keyword.fetch!(opts, :name)
    states_type = Keyword.fetch!(opts, :type)
    states_default = Keyword.fetch!(opts, :default)

    states_type_name =
      states_type
      |> Module.split()
      |> Enum.map(&Macro.underscore/1)
      |> Enum.join("_")

    quote do
      @states_field unquote(states_field)
      @states_handler unquote(handler)

      require unquote(handler)
      require EctoEnum

      states_names = @states_handler.states_names()
      EctoEnum.defenum(unquote(states_type), unquote(states_type_name), states_names)

      field_opts =
        case unquote(states_default) do
          nil -> []
          default -> [default: default]
        end

      Ecto.Schema.__field__(__MODULE__, @states_field, unquote(states_type), field_opts)
    end
  end
end