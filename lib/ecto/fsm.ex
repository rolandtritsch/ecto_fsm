defmodule Ecto.FSM do
  @moduledoc """
  Handle Ecto structures status through FSM

  Defines FSM with `Ecto.FSM.Notation` macros.

  Caller module is added the following functions:
  * `handle_action(Ecto.Schema.t() | Ecto.Changeset.t(), Ecto.FSM.action(), params :: term) :: {:ok, Ecto.Schema.t() | Ecto.Changeset.t()} | {:error, term}`
  * `handle_action!(Ecto.Schema.t() | Ecto.Changeset.t(), Ecto.FSM.action(), params :: term) :: Ecto.Schema.t() | Ecto.Changeset.t()`
  """
  alias Ecto.FSM.State

  @type trans :: atom
  @type params :: term
  @type handler :: module

  @type action :: {State.name(), trans}
  @type result :: {handler, [State.name()]}
  @type specs :: %{action => result}
  @type bypasses :: %{trans => handler}

  @type doc_key :: {:transition_doc, State.name(), trans} | {:event_doc, trans}
  @type doc :: String.t()
  @type docs :: %{doc_key => doc}
  @type info :: {:known_transition, doc} | {:bypass, doc}

  @type transition :: ({trans, params}, State.t() -> {:next_state, trans, State.t()})

  # defmacro __using__(opts) do
  #   handler = __CALLER__.module

  #   status =
  #     opts
  #     |> Keyword.get_lazy(:status, fn -> raise "Missing opt: :status" end)
  #     |> case do
  #       field when is_atom(field) -> field
  #       _ -> raise ":status opt must be an Ecto.Schema field name"
  #     end

  #   quote do
  #     alias Ecto.Changeset

  #     def state_name(s), do: Map.get(s, unquote(status))

  #     def set_state_name(s, name) do
  #       s
  #       |> Changeset.change()
  #       |> Changeset.put_change(unquote(status), name)
  #     end

  #     def status_field, do: unquote(status)

  #     def handle_action(struct, action, params \\ nil) do
  #       if Ecto.FSM.Machine.action_available?(struct, action) do
  #         do_action(struct, action, params)
  #       else
  #         cs =
  #           struct
  #           |> Changeset.change()
  #           |> Changeset.add_error(:status, "action not available in this state: #{action}")

  #         {:error, cs}
  #       end
  #     end

  #     def handle_action!(struct, action, params \\ nil) do
  #       struct
  #       |> handle_action(action, params)
  #       |> case do
  #         {:error, %Changeset{} = cs} ->
  #           cs

  #         {:error, :internal_error} ->
  #           raise "internal error"

  #         {:ok, s} ->
  #           s
  #       end
  #     end

  #     defp do_action(state, action, params) do
  #       case Ecto.FSM.Machine.event(state, {action, params}) do
  #         {:next_state, %Changeset{changes: %{}} = cs} ->
  #           {:ok, Changeset.apply_changes(cs)}

  #         {:next_state, %Changeset{} = cs} ->
  #           {:ok, cs}

  #         {:next_state, %{__struct__: __MODULE__} = s} ->
  #           {:ok, s}

  #         {:next_state, %Changeset{changes: %{}} = cs, _timeout} ->
  #           {:ok, Changeset.apply_changes(cs)}

  #         {:next_state, %Changeset{} = cs, _timeout} ->
  #           {:ok, cs}

  #         {:next_state, %{__struct__: __MODULE__} = s, _timeout} ->
  #           {:ok, s}

  #         {:error, err} ->
  #           cs =
  #             state
  #             |> Changeset.change()
  #             |> Changeset.add_error(:action, "has failed: #{inspect(err)}")

  #           {:error, cs}
  #       end
  #     rescue
  #       ExFSM.Error ->
  #         {:error, :internal_error}
  #     end

  #     defimpl ExFSM.Machine.State, for: unquote(handler) do
  #       def handlers(_), do: [unquote(handler)]

  #       def state_name(s), do: unquote(handler).state_name(s)

  #       def set_state_name(s, name), do: unquote(handler).set_state_name(s, name)
  #     end
  #   end
  # end
end
