defmodule Locker.Ext.Schema do
  @moduledoc """
  Describe locker with extension
  """
  use Ecto.FSM.Schema

  schema "lockers_ext" do
    status([Locker, Locker.Ext])
  end
end
