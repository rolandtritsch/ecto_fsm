defmodule Locker.Schema do
  @moduledoc """
  Describes Locker schema
  """
  use Ecto.FSM.Schema

  schema "lockers" do
    status(Locker)
  end
end
