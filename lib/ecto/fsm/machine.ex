defmodule Ecto.FSM.Machine do
  @moduledoc """
  Provides functions for using FSMs.

  * `Ecto.FSM.Machine.fsm/1` merge fsm from multiple handlers (see
    `Ecto.FSM` to see how to define one).
  * `Ecto.FSM.Machine.event_bypasses/1` merge bypasses from multiple
    handlers (see `Ecto.FSM` to see how to define one).
  * `Ecto.FSM.Machine.event/2` allows you to execute the correct
    handler from a state and action
  """
  require Logger

  alias Ecto.Multi
  alias Ecto.FSM.Machine.State

  @type meta_event_error :: :illegal_action | term
  @type meta_event_reply :: {:ok, State.t()} | {:error, meta_event_error}

  @doc """
  Returns `Ecto.FSM.specs()` built from all handlers
  """
  @spec fsm(State.t()) :: Ecto.FSM.specs()
  def fsm(state), do: do_fsm(State.handlers(state))

  @doc """
  Returns global bypasses
  """
  @spec event_bypasses(State.t()) :: Ecto.FSM.bypasses()
  def event_bypasses(state), do: do_event_bypasses(State.handlers(state))

  @doc """
  Returns handler for given action, if any
  """
  @spec find_handler({State.t(), Ecto.FSM.trans()}) :: Ecto.FSM.handler() | nil
  def find_handler({state, trans}) do
    {State.state_name(state), trans}
    |> do_find_handler(State.handlers(state))
  end

  @doc """
  Find bypass
  """
  @spec find_bypass_handler(State.t(), Ecto.FSM.trans()) :: Ecto.FSM.handler() | nil
  def find_bypass_handler(state, trans) do
    event_bypasses(state)[trans]
  end

  @doc """
  Returns global doc
  """
  @spec infos(State.t(), Ecto.FSM.trans()) :: Ecto.FSM.docs()
  def infos(state, action) do
    state
    |> State.handlers()
    |> do_infos(action)
  end

  @doc """
  Returns info for particular transition
  """
  @spec find_info(Ecto.FSM.State.t(), Ecto.FSM.trans()) :: Ecto.FSM.info() | nil
  def find_info(state, trans) do
    docs = infos(state, trans)

    docs
    |> Map.get({:transition_doc, State.state_name(state), trans})
    |> case do
      nil ->
        find_bypass_info(docs, trans)

      doc ->
        {:transition, doc}
    end
  end

  @doc """
  Returns available actions
  """
  @spec available_actions(State.t()) :: [Ecto.FSM.trans()]
  def available_actions(state) do
    fsm_actions =
      state
      |> Ecto.FSM.Machine.fsm()
      |> Enum.filter(fn {{from, _}, _} -> from == State.state_name(state) end)
      |> Enum.map(fn {{_, action}, _} -> action end)

    bypasses_actions =
      state
      |> Ecto.FSM.Machine.event_bypasses()
      |> Map.keys()

    Enum.uniq(fsm_actions ++ bypasses_actions)
  end

  @doc """
  Returns true if given action is available
  """
  @spec action_available?(State.t(), Ecto.FSM.trans()) :: boolean
  def action_available?(state, action) do
    actions = available_actions(state)

    if :_ in actions do
      true
    else
      action in available_actions(state)
    end
  end

  @doc """
  Meta application of the transition function, using `find_handler/2`
  to find the module implementing it.
  """
  @spec event(State.t(), {Ecto.FSM.trans(), term}) :: meta_event_reply
  def event(state, {trans, params}) do
    {state, trans}
    |> find_handler()
    |> case do
      nil ->
        do_find_bypass(state, trans, params)

      handler ->
        do_apply_event(handler, state, trans, params)
    end
  end

  ###
  ### Priv
  ###
  defp do_fsm(handlers) when is_list(handlers) do
    handlers
    |> Enum.map(& &1.fsm)
    |> Enum.concat()
    |> Enum.into(%{})
  end

  defp do_event_bypasses(handlers) when is_list(handlers),
    do: handlers |> Enum.map(& &1.event_bypasses) |> Enum.concat() |> Enum.into(%{})

  defp do_infos(handlers, _trans) when is_list(handlers) do
    handlers
    |> Enum.map(& &1.docs)
    |> Enum.concat()
    |> Enum.into(%{})
  end

  defp do_find_bypass(state, trans, params) do
    state
    |> find_bypass_handler(trans)
    |> case do
      nil ->
        {:error, :illegal_action}

      handler ->
        do_apply_bypass(handler, state, trans, params)
    end
  end

  defp do_find_handler({state_name, trans}, handlers) when is_list(handlers) do
    handlers
    |> do_fsm()
    |> Map.get({state_name, trans})
    |> case do
      {handler, _} -> handler
      _ -> nil
    end
  end

  defp do_apply_bypass(handler, state, action, params) do
    handler
    |> apply(action, [params, state])
    |> do_event_result(handler, state, action)
  end

  defp do_apply_event(handler, state, action, params) do
    orig = State.state_name(state)

    handler
    |> apply(orig, [{action, params}, state])
    |> do_event_result(handler, state, action)
  end

  defp do_event_result({:keep_state, state}, _, _, _), do: {:ok, state}

  defp do_event_result({:next_state, state_name, %Multi{} = state}, _, input_state, _) do
    init_multi =
      Multi.new()
      |> Multi.run(:__fsm_input__, fn _repo, _changes -> {:ok, input_state} end)

    state =
      init_multi
      |> Multi.append(state)
      |> Multi.append(State.set_state_name(init_multi, state_name))

    {:ok, state}
  end

  defp do_event_result({:next_state, state_name, state}, _, _, _) do
    {:ok, State.set_state_name(state, state_name)}
  end

  defp do_event_result({:error, _} = e, _, _, _), do: e

  defp do_event_result(_other, handler, state, action) do
    orig = State.state_name(state)
    raise Ecto.FSM.Error, handler: handler, statename: orig, action: action
  end

  defp find_bypass_info(docs, action) do
    docs
    |> Map.get({:event_doc, action})
    |> case do
      nil ->
        nil

      doc ->
        {:bypass, doc}
    end
  end
end
