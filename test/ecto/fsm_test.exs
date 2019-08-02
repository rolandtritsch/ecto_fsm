defmodule Ecto.FSM.NotationTest do
  use ExUnit.Case

  # doctest Ecto.FSM

  describe "def handle_event(...)" do
    setup do
      Code.compiler_options(ignore_module_conflict: true)

      on_exit(fn ->
        Code.compiler_options(ignore_module_conflict: false)
      end)
    end

    test "block syntax - single term" do
      res =
        defmodule TestFsm do
          use Ecto.FSM

          def handle_event(:action, :goto_end, :init, s) do
            {:next_state, :end, s}
          end

          def a_function, do: :ok
        end

      assert match?({:module, _, _, _}, res)

      {:module, mod, _, _} = res
      assert Kernel.function_exported?(mod, :handle_event, 4)
      assert Kernel.function_exported?(mod, :a_function, 0)
      assert match?([:goto_end], mod.__fsm__(:actions))
      assert match?([:end, :init], mod.__fsm__(:states))
    end

    test "block syntax - multiple term" do
      res =
        defmodule TestFsm do
          use Ecto.FSM

          def handle_event(:action, :goto_end, :init, s) do
            _ = :dead_code
            {:next_state, :end, s}
          end

          def a_function, do: :ok
        end

      assert match?({:module, _, _, _}, res)

      {:module, mod, _, _} = res
      assert Kernel.function_exported?(mod, :handle_event, 4)
      assert Kernel.function_exported?(mod, :a_function, 0)
      assert match?([:goto_end], mod.__fsm__(:actions))
      assert match?([:end, :init], mod.__fsm__(:states))
    end

    test "block syntax - case structure" do
      res =
        defmodule TestFsm do
          use Ecto.FSM

          def handle_event(:action, :goto_end, :init, s) do
            case s do
              :one -> {:next_state, :end_one, s}
              :two -> {:next_state, :end_two, s}
            end
          end
        end

      assert match?({:module, _, _, _}, res)

      {:module, mod, _, _} = res
      assert match?([:goto_end], mod.__fsm__(:actions))
      assert match?([:end_one, :end_two, :init], mod.__fsm__(:states))
    end

    test "block syntax - if structure" do
      res =
        defmodule TestFsm do
          use Ecto.FSM

          def handle_event(:action, :goto_end, :init, s) do
            if true do
              {:next_state, :end_one, s}
            else
              {:next_state, :end_two, s}
            end
          end
        end

      assert match?({:module, _, _, _}, res)

      {:module, mod, _, _} = res
      assert match?([:goto_end], mod.__fsm__(:actions))
      assert match?([:end_one, :end_two, :init], mod.__fsm__(:states))
    end

    test "block syntax - unless structure" do
      res =
        defmodule TestFsm do
          use Ecto.FSM

          def handle_event(:action, :goto_end, :init, s) do
            cond do
              s == 1 ->
                {:next_state, :end_one, s}

              s == 2 ->
                {:next_state, :end_two, s}

              true ->
                {:next_state, :end_three, s}
            end
          end
        end

      assert match?({:module, _, _, _}, res)

      {:module, mod, _, _} = res
      assert match?([:goto_end], mod.__fsm__(:actions))
      assert match?([:end_one, :end_three, :end_two, :init], mod.__fsm__(:states))
    end

    test "keyword syntax" do
      res =
        defmodule TestFsm do
          use Ecto.FSM

          def handle_event(:action, :goto_end, :init, s), do: {:next_state, :end, s}
        end

      assert match?({:module, _, _, _}, res)

      {:module, mod, _, _} = res
      assert match?([:goto_end], mod.__fsm__(:actions))
      assert Kernel.function_exported?(mod, :handle_event, 4)
    end

    test "with guard" do
      res =
        defmodule TestFsm do
          use Ecto.FSM

          def handle_event(:action, action, state, s)
              when state in [:init, :another] and
                     action == :goto_end1,
              do: {:next_state, :end, s}
        end

      assert match?({:module, _, _, _}, res)

      {:module, mod, _, _} = res
      assert match?([:goto_end1], mod.__fsm__(:actions))
      assert match?([:another, :end, :init], mod.__fsm__(:states))
      assert Kernel.function_exported?(mod, :handle_event, 4)
    end
  end
end
