defmodule Locker.Ext do
  @moduledoc """
  Describes Locker FSM extension
  """
  use Ecto.FSM

  @doc "Secret unlock"
  transition locked({:dont_tell_anyone, _}, s) do
    {:next_state, :unlocked, s}
  end
end
