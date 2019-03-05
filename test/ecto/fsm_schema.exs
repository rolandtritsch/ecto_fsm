defmodule Ecto.FSM.SchemaTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias Ecto.FSM

  doctest Ecto.FSM.SchemaTest

  describe "Ecto.FSM" do
    setup :new_locker

    test ".action/3", %{locker: s} do
      res =
        s
        |> Changeset.change()
        |> FSM.action(:one, nil)

      assert match?(%Changeset{changes: %{status: :one}}, res)
    end
  end

  defp new_locker(_ctx) do
    {:ok, locker: %Locker.Schema{status: :locked}}
  end
end
