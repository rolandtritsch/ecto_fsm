defmodule Ecto.FSM.SchemaTest do
  use ExUnit.Case

  alias Ecto.Changeset
  alias Ecto.FSM

  doctest Ecto.FSM.SchemaTest

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
        |> FSM.action(:keep_multi, :myarg)

      assert match?(%Multi{}, res)

      _state_changeset =
        res
        |> Multi.to_list()
        |> Keyword.get(:__fsm_state__)
        |> IO.inspect(label: "STATE_CS")
    end

    test "returns multi (next_state)", %{locker: s} do
      res =
        s
        |> Changeset.change()
        |> FSM.action(:next_multi, :myarg)

      assert match?(%Multi{}, res)

      _state_changeset =
        res
        |> Multi.to_list()
        |> Keyword.get(:__fsm_state__)
        |> IO.inspect(label: "STATE_CS")
    end
  end

  defp new_locker(_ctx) do
    {:ok, locker: %Locker.Schema{status: :locked}}
  end
end
