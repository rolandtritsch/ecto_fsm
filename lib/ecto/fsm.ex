defmodule Ecto.FSM do
  @moduledoc """
  Handle Ecto structures status through FSM
  """
  defmacro __using__(opts) do
    handler = __CALLER__.module

    status =
      opts
      |> Keyword.get_lazy(:status, fn -> raise "Missing opt: :status" end)
      |> case do
        field when is_atom(field) -> field
        _ -> raise ":status opt must be an Ecto.Schema field name"
      end

    quote do
      use ExFSM

      import Ecto.FSM.Helpers

      alias Ecto.Changeset
      alias Ecto.Multi

      def state_name(s), do: Map.get(s, unquote(status))

      def set_state_name(s, name) do
        s
        |> Changeset.change()
        |> Changeset.put_change(unquote(status), name)
      end

      def status_field, do: unquote(status)

      def handle_action(struct, action, params \\ nil) do
        if ExFSM.Machine.action_available?(struct, action) do
          do_action(struct, action, params)
        else
          cs =
            struct
            |> Changeset.change()
            |> Changeset.add_error(:status, "action not available in this state: #{action}")

          {:error, cs}
        end
      end

      def handle_action!(struct, action, params \\ nil) do
        struct
        |> handle_action(action, params)
        |> case do
          {:error, %Changeset{} = cs} ->
            cs

          {:error, :internal_error} ->
            raise "internal error"

          {:ok, s} ->
            s
        end
      end

      defp do_action(state, action, params) do
        case ExFSM.Machine.event(state, {action, params}) do
          {:next_state, %Changeset{changes: %{}} = cs} ->
            {:ok, Changeset.apply_changes(cs)}

          {:next_state, %Changeset{} = cs} ->
            {:ok, cs}

          {:next_state, %{__struct__: __MODULE__} = s} ->
            {:ok, s}

          {:next_state, %Changeset{changes: %{}} = cs, _timeout} ->
            {:ok, Changeset.apply_changes(cs)}

          {:next_state, %Changeset{} = cs, _timeout} ->
            {:ok, cs}

          {:next_state, %{__struct__: __MODULE__} = s, _timeout} ->
            {:ok, s}

          {:error, err} ->
            cs =
              state
              |> Changeset.change()
              |> Changeset.add_error(:action, "has failed: #{inspect(err)}")

            {:error, cs}
        end
      rescue
        ExFSM.Error ->
          {:error, :internal_error}
      end

      defimpl ExFSM.Machine.State, for: unquote(handler) do
        def handlers(_), do: [unquote(handler)]

        def state_name(s), do: unquote(handler).state_name(s)

        def set_state_name(s, name), do: unquote(handler).set_state_name(s, name)
      end
    end
  end
end

defimpl ExFSM.Machine.State, for: Ecto.Changeset do
  alias Ecto.Changeset

  def handlers(cs), do: [handler(cs)]

  def state_name(%Changeset{} = cs), do: Changeset.get_field(cs, status_field(cs))

  def set_state_name(%Changeset{} = cs, name) when is_atom(name) do
    Changeset.put_change(cs, status_field(cs), name)
  end

  ###
  ### Priv
  ###  
  defp handler(%Changeset{data: %{__struct__: handler}}), do: handler

  defp status_field(cs), do: cs |> handler() |> apply(:status_field, [])
end
