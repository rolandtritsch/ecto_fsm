defmodule Ecto.FSM.NotationTest do
  use ExUnit.Case

  doctest Ecto.FSM.Notation

  describe "FSM definition" do
    test ".transition/2" do
      {:module, mod, _, _} =
        defmodule Elixir.Fsm1 do
          use Ecto.FSM.Notation

          transition init({:action, _}, s) do
            {:next_state, :end, s}
          end
        end

      assert match?(%{{:init, :action} => {Elixir.Fsm1, [:end]}}, mod.fsm())
    end
  end
end
