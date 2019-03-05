defmodule Ecto.FSM.NotationTest do
  use ExUnit.Case

  doctest Ecto.FSM

  describe ".transition/2" do
    setup do
      Code.compiler_options(ignore_module_conflict: true)

      on_exit(fn ->
        Code.compiler_options(ignore_module_conflict: false)
      end)
    end

    test "...base transition" do
      {:module, mod, _, _} =
        defmodule TestFsm do
          use Ecto.FSM

          transition init({:action, _}, s) do
            {:next_state, :end, s}
          end
        end

      assert match?(%{{:init, :action} => {^mod, [:end]}}, mod.fsm())
    end

    test "...default transition" do
      {:module, mod, _, _} =
        defmodule TestFsm do
          use Ecto.FSM

          transition init({:action, _}, s) do
            {:next_state, :end, s}
          end

          transition init({_, _}, s) do
            {:next_state, :error, s}
          end
        end

      assert match?(
               %{
                 {:init, :action} => {^mod, [:end]},
                 {:init, :_} => {^mod, [:error]}
               },
               mod.fsm()
             )
    end
  end

  describe ".bypass/2" do
    setup do
      Code.compiler_options(ignore_module_conflict: true)

      on_exit(fn ->
        Code.compiler_options(ignore_module_conflict: false)
      end)
    end

    test "...base bypass" do
      {:module, mod, _, _} =
        defmodule TestFsm do
          use Ecto.FSM

          bypass goto_s1(_, s) do
            {:next_state, :s1, s}
          end
        end

      assert match?(%{:goto_s1 => ^mod}, mod.event_bypasses())
    end
  end
end
