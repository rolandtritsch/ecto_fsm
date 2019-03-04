defmodule Ecto.FSM.Notation do
  @moduledoc """
  Provides macros for defining FSM

  Defines FSM with `transition/2` and `bypass/2` macros.

  Caller module is added the following functions:
  * `fsm() :: Ecto.FSM.specs()`
  * `docs() :: Ecto.FSM.docs()`

  Examples:

      iex> defmodule Elixir.Door do
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

  defmacro __using__(_opts) do
    quote do
      import Ecto.FSM.Notation
      @fsm %{}
      @bypasses %{}
      @docs %{}
      @to nil

      @before_compile Ecto.FSM.Notation
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
  defmacro transition({state, _meta, [{trans, _params} | _rest]} = signature, body_block) do
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
  defp find_nextstates({:{}, _, [:next_state, state | _]}) when is_atom(state), do: [state]
  defp find_nextstates({_, _, asts}), do: find_nextstates(asts)
  defp find_nextstates({_, asts}), do: find_nextstates(asts)
  defp find_nextstates(asts) when is_list(asts), do: Enum.flat_map(asts, &find_nextstates/1)
  defp find_nextstates(_), do: []
end
