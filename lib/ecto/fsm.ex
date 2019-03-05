defmodule Ecto.FSM do
  @moduledoc """
  Handle Ecto structures status through FSM

  Provides macros for defining FSM

  Defines FSM with `transition/2` and `bypass/2` macros.

  Caller module is added the following functions:
  * `fsm() :: Ecto.FSM.specs()`
  * `docs() :: Ecto.FSM.docs()`

  Transition functions must return `Ecto.FSM.transition_ret`.

  Examples:

      iex> defmodule Elixir.Door do
      ...>   use Ecto.FSM
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
      ...>
      ...>   @doc "Force the door"
      ...>   bypass force(_, s) do
      ...>     {:next_state, :destroyed, s}
      ...>   end
      ...> end
      ...> Door.fsm()
      %{
        {:closed, :close} => {Door, [:closed]}, {:closed, :else} => {Door, [:closed]},
        {:closed, :open} => {Door, [:opened]}, {:opened, :close} => {Door, [:closed]},
        {:opened, :else} => {Door, [:opened]}, {:opened, :open} => {Door, [:opened]}
      }
      ...> Door.docs()
      %{
        {:transition_doc, :closed, :close} => "Close to close",
        {:transition_doc, :closed, :else} => nil,
        {:transition_doc, :closed, :open} => "Close to open",
        {:transition_doc, :opened, :close} => "Open to close",
        {:transition_doc, :opened, :else} => nil,
        {:transition_doc, :opened, :open} => "Open to open",
        {:event_doc, :force} => "Force the door"
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
  @type info :: {:transition, doc} | {:bypass, doc}

  @type transition_ret :: {:next_state, State.name(), State.t()} | {:keep_state, State.t()}
  @type transition :: ({trans, params}, State.t() -> transition_ret)

  defmacro __using__(_opts) do
    quote do
      import Ecto.FSM

      @fsm %{}
      @bypasses %{}
      @docs %{}
      @to nil
      @__states_names__ []

      @before_compile Ecto.FSM
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

      @doc """
      Returns this FSM's states names
      """
      @spec states_names() :: [Ecto.State.name()]
      def states_names, do: @__states_names__
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
  defmacro transition({state, _meta, [{trans, _params} | _rest]} = signature, body_block) do
    do_block = Keyword.get(body_block, :do)

    transition =
      case trans do
        {:_, _, _} -> :_
        t when is_atom(t) -> t
      end

    next_states =
      do_block
      |> find_nextstates(state)
      |> Enum.uniq()

    quote do
      state_name = unquote(state)
      trans = unquote(transition)
      next_states = @to || unquote(next_states)

      @fsm Map.put(@fsm, {state_name, trans}, {__MODULE__, next_states})
      @__states_names__ [state_name | @__states_names__] |> Enum.uniq()

      doc =
        __MODULE__
        |> Module.get_attribute(:doc)
        |> case do
          nil -> nil
          {_line, doc} -> doc
          doc when is_binary(doc) -> doc
        end

      @docs Map.put(@docs, {:transition_doc, state_name, trans}, doc)
      def unquote(signature), do: unquote(do_block)
      @to nil
    end
  end

  @doc """
  Define a function of type `bypass`, ie which can be applied on any state
  """
  defmacro bypass({trans, _meta, _args} = signature, body_block) do
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
  defp find_nextstates({:keep_state, _state_ast}, state_name),
    do: [state_name]

  defp find_nextstates({:{}, _, [:next_state, state_name, _state_ast]}, _)
       when is_atom(state_name),
       do: [state_name]

  defp find_nextstates({_, _, asts}, state_name),
    do: find_nextstates(asts, state_name)

  defp find_nextstates({_, asts}, state_name),
    do: find_nextstates(asts, state_name)

  defp find_nextstates(asts, state_name) when is_list(asts),
    do: Enum.flat_map(asts, fn ast -> find_nextstates(ast, state_name) end)

  defp find_nextstates(_, _),
    do: []

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
