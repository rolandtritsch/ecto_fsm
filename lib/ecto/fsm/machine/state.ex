defprotocol Ecto.FSM.Machine.State do
  @moduledoc """
  Defines a protocol for get / set state name from a structure.
  """
  @type name :: Ecto.FSM.State.name()

  @doc """
  Retrieve current state handlers from state object, return [Handler1,Handler2]
  """
  @spec handlers(t) :: [Ecto.FSM.handler()]
  def handlers(state)

  @doc """
  Retrieve current state name from state object
  """
  @spec state_name(t) :: name()
  def state_name(state)

  @doc """
  Set new state name
  """
  @spec set_state_name(t, name) :: t
  def set_state_name(state, name)
end

defimpl Ecto.FSM.Machine.State, for: Ecto.Changeset do
  alias Ecto.Changeset

  def handlers(cs), do: [handler(cs)]

  def state_name(%Changeset{} = cs), do: Changeset.get_field(cs, status_field(cs))

  def set_state_name(%Changeset{} = cs, name) when is_atom(name) do
    Changeset.put_change(cs, status_field(cs), name)
  end

  ###
  ### Priv
  ###  
  defp handler(%Changeset{data: %{__struct__: handler}}), do: handler

  defp status_field(cs), do: cs |> handler() |> apply(:status_field, [])
end
