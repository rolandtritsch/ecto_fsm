defmodule Ecto.FSM.Helpers do
  @moduledoc """
  Utilities functions imported into module using `Ecto.FSM`
  """

  @doc """
  Generates `state` field for FSM
  """
  defmacro state(opts \\ []) do
    field = Keyword.get(opts, :field, :state)
    type = :string
    
    quote do
      Ecto.Schema.field(unquote(field), unquote(type))
    end
  end
end
