defmodule Locker do
  @moduledoc """
  Implements pin code locker (code: 1234)
  """
  use Ecto.FSM

  @doc "Valid input: 1"
  transition locked({:one, _}, s) do
    {:next_state, :one, s}
  end

  @doc "Invalid input: :locked"
  transition locked({_, _}, s) do
    {:keep_state, s}
  end

  @doc "Valid input: 1,2"
  transition one({:two, _}, s) do
    {:next_state, :two, s}
  end

  @doc "Invalid input: :locked"
  transition one({_, _}, s) do
    {:next_state, :locked, s}
  end

  @doc "Valid input: 1,2,3"
  transition two({:three, _}, s) do
    {:next_state, :three, s}
  end

  @doc "Invalid input: :locked"
  transition two({_, _}, s) do
    {:next_state, :locked, s}
  end

  @doc "Valid input: 1,2,3,4"
  transition three({:four, _}, s) do
    {:next_state, :unlocked, s}
  end

  @doc "Invalid input: :locked"
  transition three({_, _}, s) do
    {:next_state, :locked, s}
  end

  @doc "Lock"
  transition unlocked({:lock, _}, s) do
    {:next_state, :locked, s}
  end

  @doc "Reset locker"
  bypass c(_, s) do
    {:next_state, :locked, s}
  end
end
