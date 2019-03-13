defmodule Ecto.FSM.SchemaTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias Ecto.Multi
  alias Ecto.FSM

  doctest Ecto.FSM.Schema

  describe ".action/3" do
    setup :new_locker

    test "returns changeset", %{locker: s} do
      res =
        s
        |> Changeset.change()
        |> FSM.action(:one, nil)

      assert match?(%Changeset{changes: %{status: :one}}, res)
    end

    test "returns multi (keep_state)", %{locker: s} do
      res =
        s
        |> Changeset.change()
        |> FSM.action(:one, nil)
        |> FSM.action(:two, nil)
        |> FSM.action(:three, nil)
        |> FSM.action(:four, nil)
        |> FSM.action(:keep_multi, :myarg)

      assert match?(%Multi{operations: [op: _]}, res)
    end

    test "returns multi (next_state)", %{locker: s} do
      res =
        s
        |> Changeset.change()
        |> FSM.action(:one, nil)
        |> FSM.action(:two, nil)
        |> FSM.action(:three, nil)
        |> FSM.action(:four, nil)
        |> FSM.action(:next_multi, :myarg)

      assert match?(%Multi{}, res)

      assert match?(
               [:__fsm_input__, :op, :__fsm_state__],
               res |> Multi.to_list() |> Keyword.keys()
             )
    end
  end

  describe ".action/3 on Locker with extension" do
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
