defprotocol Ecto.FSM.Schema.State do
  @moduledoc """
  Defines a protocol for accessing Ecto schema status field
  """

  @doc """
  Return schema's status field
  """
  @spec field(t) :: atom
  def field(state)
end

defimpl Ecto.FSM.Schema.State, for: Ecto.Changeset do
  def field(%Ecto.Changeset{data: data}), do: Ecto.FSM.Schema.State.field(data)
end
