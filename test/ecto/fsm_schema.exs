defmodule Ecto.FSM.SchemaTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias Ecto.FSM

  doctest Ecto.FSM.Schema

  describe ".action/3" do
    setup :new_locker

    test "single", %{locker: s} do
      res =
        s
        |> Changeset.change()
        |> FSM.action(:one, nil)

      assert match?(%Changeset{changes: %{status: :one}}, res)
    end

    test "multiple actions", %{locker: s} do
      res =
        s
        |> Changeset.change()
        |> FSM.action(:one, nil)
        |> FSM.action(:two, nil)

      assert match?(%Changeset{changes: %{status: :two}}, res)
    end
  end

  describe ".action/3 with extension" do
    setup :new_locker_ext

    test "unlock", %{locker: s} do
      res =
        s
        |> Changeset.change()
        |> FSM.action(:dont_tell_anyone, nil)

      assert match?(%Changeset{changes: %{status: :unlocked}}, res)
    end
  end

  defp new_locker(_ctx) do
    {:ok, locker: %Locker.Schema{status: :locked}}
  end

  defp new_locker_ext(_ctx) do
    {:ok, locker: %Locker.Ext.Schema{status: :locked}}
  end
end
