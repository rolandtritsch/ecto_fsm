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

    states_handlers =
      states_schema
      |> Module.get_attribute(:states_handlers)
      |> case do
        nil ->
          raise """
          Schema #{env.module} is missing a status field.

          You can add one with `Ecto.FSM.Schema.status/{1,2}`.
          """

        l ->
          l
      end

    states_type = Module.get_attribute(states_schema, :states_type)
    states_field = Module.get_attribute(states_schema, :states_field)

    quote do
      alias Ecto.Changeset

      def state_name(s) do
        s
        |> Changeset.change()
        |> Changeset.get_field(unquote(states_field))
      end

      def set_state_name(s, name) do
        s
        |> Changeset.change()
        |> Changeset.put_change(unquote(states_field), name)
      end

      def states_type, do: unquote(states_type)

      def states_field, do: unquote(states_field)

      defimpl Ecto.FSM.Machine.State do
        def handlers(_), do: unquote(states_handlers)

        def state_name(s), do: unquote(states_schema).state_name(s)

        def set_state_name(s, name), do: unquote(states_schema).set_state_name(s, name)
      end

      defimpl Ecto.FSM.Schema.State do
        def field(_), do: unquote(states_field)
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
  defmacro status(handlers, opts \\ []) do
    handlers = List.wrap(handlers)

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
      @states_type unquote(states_type)
      @states_field unquote(states_field)
      @states_handlers unquote(handlers)

      require EctoEnum
      Ecto.FSM.Schema.__requires__(unquote(handlers))

      states_names =
        @states_handlers
        |> Enum.reduce([], fn handler, acc -> handler.states_names() ++ acc end)

      EctoEnum.defenum(unquote(states_type), unquote(states_type_name), states_names)

      field_opts =
        case unquote(states_default) do
          nil -> []
          default -> [default: default]
        end

      Ecto.Schema.__field__(__MODULE__, @states_field, unquote(states_type), field_opts)
    end
  end

  @doc false
  defmacro __requires__(handlers) do
    handlers
    |> Enum.map(&__require__/1)
  end

  @doc false
  def __require__(handler) do
    quote do
      require unquote(handler)
    end
  end
end
