defmodule Ecto.FSM.Migration do
  @moduledoc """
  Provides functions for FSM schema migrations
  """

  defmacro __using__(_opts) do
    quote do
      import Ecto.FSM.Migration
    end
  end

  @doc """
  Creates enumeration type for `states` field
  """
  def create_states_type(schema) do
    schema
    |> apply(:states_type, [])
    |> apply(:create_type, [])
  end

  @doc """
  Creates column for `states` field
  """
  defmacro states(schema) do
    quote bind_quoted: binding() do
      states_field = apply(schema, :states_field, [])

      states_type =
        schema
        |> apply(:states_type, [])
        |> apply(:type, [])

      Ecto.Migration.add(states_field, states_type, [])
    end
  end
end
