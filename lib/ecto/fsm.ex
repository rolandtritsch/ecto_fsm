defmodule Ecto.FSM do
  @moduledoc """
  Handle Ecto structures status through FSM

  Defines FSM with `transition/2` and
  `bypass/2` macros.

  Caller module is added the following functions:
  * `fsm() :: Ecto.FSM.specs()`
  * `docs() :: Ecto.FSM.docs()`
  * `handle_action(Ecto.Schema.t() | Ecto.Changeset.t(), Ecto.FSM.action(), params :: term) :: {:ok, Ecto.Schema.t() | Ecto.Changeset.t()} | {:error, term}`
  * `handle_action!(Ecto.Schema.t() | Ecto.Changeset.t(), Ecto.FSM.action(), params :: term) :: Ecto.Schema.t() | Ecto.Changeset.t()`

  Example

      iex> defmodule Door do
      ...>   use Ecto.FSM.Notation
      ...> 
      ...>   @doc "Close to open"
      ...>   @to [:opened]
      ...>   transition closed({:open, _}, s) do
      ...>     {:next_state, :opened, s}
      ...>   end
      ...> 
      ...>   @doc "Close to close"
      ...>   transition closed({:close, _}, s) do
      ...>     {:next_state, :closed, s}
      ...>   end
      ...> 
      ...>   transition closed({:else, _}, s) do
      ...>     {:next_state, :closed, s}
      ...>   end
      ...> 
      ...>   @doc "Open to open"
      ...>   transition opened({:open, _}, s) do
      ...>     {:next_state, :opened, s}
      ...>   end
      ...> 
      ...>   @doc "Open to close"
      ...>   @to [:closed]
      ...>   transition opened({:close, _}, s) do
      ...>     {:next_state, :closed, s}
      ...>   end
      ...> 
      ...>   transition opened({:else, _}, s) do
      ...>     {:next_state, :opened, s}
      ...>   end
      ...> end
      ...> Door.fsm()
      %{
        {:closed, :close} => {Door, [:closed]}, {:closed, :else} => {Door, [:closed]},
        {:closed, :open} => {Door, [:opened]}, {:opened, :close} => {Door, [:closed]},
        {:opened, :else} => {Door, [:opened]}, {:opened, :open} => {Door, [:opened]}
      }

      iex> Door.docs()
      %{
        {:transition_doc, :closed, :close} => "Close to close",
        {:transition_doc, :closed, :else} => nil,
        {:transition_doc, :closed, :open} => "Close to open",
        {:transition_doc, :opened, :close} => "Open to close",
        {:transition_doc, :opened, :else} => nil,
        {:transition_doc, :opened, :open} => "Open to open"
      }
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
      import Ecto.FSM
      @fsm %{}
      @bypasses %{}
      @docs %{}
      @to nil

      @before_compile Ecto.FSM

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
        if Ecto.FSM.Machine.action_available?(struct, action) do
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
        case Ecto.FSM.Machine.event(state, {action, params}) do
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

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Returns this handler's FSM as `spec()`
      """
      @spec fsm() :: Ecto.FSM.specs()
      def fsm, do: @fsm

      @doc """
      Returns this handler's FSM bypasses as `spec()`
      """
      @spec event_bypasses() :: Ecto.FSM.bypasses()
      def event_bypasses, do: @bypasses

      @doc """
      Returns this FSM's doc map
      """
      @spec docs() :: Ecto.FSM.docs()
      def docs, do: @docs
    end
  end

  @doc """
  Define a function of type `transition` describing a state and its
  transition. The function name is the state name, the transition is the
  first argument. A state object can be modified and is the second argument.

  ```
  deftrans opened({:close_door, _params}, state) do
    {:next_state, :closed, state}
  end
  ```
  """
  defmacro deftrans({state, _meta, [{trans, _params} | _rest]} = signature, body_block) do
    quote do
      @fsm Map.put(
             @fsm,
             {unquote(state), unquote(trans)},
             {__MODULE__, @to || unquote(Enum.uniq(find_nextstates(body_block[:do])))}
           )
      doc =
        __MODULE__
        |> Module.get_attribute(:doc)
        |> case do
          nil -> nil
          {_line, doc} -> doc
          doc when is_binary(doc) -> doc
        end

      @docs Map.put(@docs, {:transition_doc, unquote(state), unquote(trans)}, doc)
      def unquote(signature), do: unquote(body_block[:do])
      @to nil
    end
  end

  @doc """
  Define a function of type `bypass`, ie which can be applied on any state
  """
  defmacro defbypass({trans, _meta, _args} = signature, body_block) do
    quote do
      @bypasses Map.put(@bypasses, unquote(trans), __MODULE__)
      doc =
        __MODULE__
        |> Module.get_attribute(:doc)
        |> case do
          nil -> nil
          {_line, doc} -> doc
          doc when is_binary(doc) -> doc
        end

      @docs Map.put(@docs, {:event_doc, unquote(trans)}, doc)
      def unquote(signature), do: unquote(body_block[:do])
    end
  end

  ###
  ### Priv
  ###
  defp find_nextstates({:{}, _, [:next_state, state | _]}) when is_atom(state), do: [state]
  defp find_nextstates({_, _, asts}), do: find_nextstates(asts)
  defp find_nextstates({_, asts}), do: find_nextstates(asts)
  defp find_nextstates(asts) when is_list(asts), do: Enum.flat_map(asts, &find_nextstates/1)
  defp find_nextstates(_), do: []
end
