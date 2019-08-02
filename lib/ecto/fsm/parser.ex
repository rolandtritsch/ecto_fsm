defmodule Ecto.FSM.Parser do
  @moduledoc """
  FSM parse: gather actions, states and transition from AST
  """
  defmodule State do
    @moduledoc false
    defstruct [:actions, :states, :transitions]

    def new,
      do: %__MODULE__{
        actions: MapSet.new(),
        states: MapSet.new(),
        transitions: MapSet.new()
      }
  end

  def __parse__(fsm, sig, body) do
    fsm
    |> parse_sig(sig)
    |> parse_do_block(body)
  end

  ###
  ### Priv
  ### 
  defp parse_sig(fsm, {:handle_event, _, [:action, action_arg, state_arg, _]}) do
    fsm
    |> parse_action_arg(action_arg)
    |> parse_state_arg(state_arg)
  end

  defp parse_sig(
         fsm,
         {:when, _, [{:handle_event, _, [:action, action_arg, state_arg, _]} | guards]}
       ) do
    {action_argname, _, _} = action_arg
    {state_argname, _, _} = state_arg

    guards
    |> Enum.reduce(fsm, &parse_guard(&2, &1, action_argname, state_argname))
  end

  defp parse_action_arg(fsm, action_arg) when is_atom(action_arg),
    do: %{fsm | actions: MapSet.put(fsm.actions, action_arg)}

  defp parse_state_arg(fsm, state_arg) when is_atom(state_arg),
    do: %{fsm | states: MapSet.put(fsm.states, state_arg)}

  defp parse_guard(fsm, {:and, _, clauses}, action, state) do
    clauses
    |> Enum.reduce(fsm, &parse_guard(&2, &1, action, state))
  end

  defp parse_guard(fsm, {:in, _, [{name, _, _}, values]}, action, state) do
    cond do
      name == action ->
        %{fsm | actions: MapSet.union(fsm.actions, MapSet.new(values))}

      name == state ->
        %{fsm | states: MapSet.union(fsm.states, MapSet.new(values))}

      true ->
        fsm
    end
  end

  defp parse_guard(fsm, {:==, _, [{name, _, _}, value]}, action, state) do
    cond do
      name == action ->
        %{fsm | actions: MapSet.put(fsm.actions, value)}

      name == state ->
        %{fsm | states: MapSet.put(fsm.states, value)}

      true ->
        fsm
    end
  end

  defp parse_do_block(fsm, do: block), do: parse_block(fsm, block)

  defp parse_do_block(fsm, _), do: fsm

  defp parse_block(fsm, {:__block__, _, terms}), do: parse_terms(fsm, terms)

  defp parse_block(fsm, term), do: parse_term(fsm, term)

  # Look into last term of the block only
  defp parse_terms(fsm, [term]), do: parse_term(fsm, term)

  defp parse_terms(fsm, [_term | terms]), do: parse_terms(fsm, terms)

  defp parse_term(fsm, {:{}, _, [:next_state, state, _]}) do
    fsm
    |> add_transitions([state])
    |> Map.put(:states, MapSet.put(fsm.states, state))
  end

  defp parse_term(fsm, {:case, _, [_, [do: clauses]]}) do
    clauses
    |> Enum.reduce(fsm, fn {:->, _, [_guard, block]}, fsm ->
      parse_block(fsm, block)
    end)
  end

  defp parse_term(fsm, {:cond, _, [[do: clauses]]}) do
    clauses
    |> Enum.reduce(fsm, fn {:->, _, [_guard, block]}, fsm ->
      parse_block(fsm, block)
    end)
  end

  defp parse_term(fsm, {:if, _, [_, [do: do_block, else: else_block]]}) do
    [do_block, else_block]
    |> Enum.reduce(fsm, &parse_block(&2, &1))
  end

  # defp parse_term(fsm, _), do: fsm

  defp add_transitions(fsm, states) do
    transitions =
      fsm.states
      |> Enum.map(&{&1, states})

    %{fsm | transitions: transitions}
  end
end
