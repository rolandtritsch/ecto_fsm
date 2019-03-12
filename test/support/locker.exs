defmodule Locker do
  @moduledoc """
  Implements pin code locker (code: 1234)
  """
  use Ecto.FSM

  alias Ecto.Multi

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

  @doc "keep_state and returns `Ecto.Multi` as state"
  transition unlocked({:keep_multi, args}, s) do
    multi =
      Multi.new()
      |> Multi.run(:op, fn _ -> {:ok, {s, args}} end)

    {:keep_state, multi}
  end

  @doc "next_state and returns `Ecto.Multi` as state"
  transition unlocked({:next_multi, args}, s) do
    multi =
      Multi.new()
      |> Multi.run(:op, fn _ -> {:ok, {s, args}} end)

    {:next_state, :locked, multi}
  end

  @doc "Reset locker"
  bypass c(_, s) do
    {:next_state, :locked, s}
  end
end
