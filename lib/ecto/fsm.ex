defmodule Ecto.FSM do
  @moduledoc """
  Use this module to define introspectable FSM

  From a developer point of view, `Ecto.FSM` tries to be as close as
  possible to OTP's `gen_statem` behaviour.
  """
  defstruct [:actions, :states, :transitions]

  defmacro __using__(_opts) do
    fsm = Ecto.FSM.Parser.State.new()

    Module.put_attribute(__CALLER__.module, :__fsm__, fsm)

    quote do
      import Kernel, except: [def: 2]
      import Ecto.FSM, only: [def: 2]

      @before_compile Ecto.FSM
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __fsm__(:actions), do: @__fsm__.actions |> MapSet.to_list()
      def __fsm__(:states), do: @__fsm__.states |> MapSet.to_list()
    end
  end

  @doc """
  Collect from and to states when defining `handle_event`
  """
  defmacro def({:handle_event, _, [_, _, _, _]} = sig, body),
    do: __def_transition__(__CALLER__, sig, body)

  defmacro def({:when, _, [{:handle_event, _, [_, _, _, _]} | _]} = sig, body),
    do: __def_transition__(__CALLER__, sig, body)

  defmacro def(sig, body) do
    quote do
      Kernel.def(unquote(sig), unquote(body))
    end
  end

  ###
  ### Priv
  ###
  defp __def_transition__(env, sig, body) do
    fsm =
      env.module
      |> Module.get_attribute(:__fsm__)
      |> Ecto.FSM.Parser.__parse__(sig, body)

    Module.put_attribute(env.module, :__fsm__, fsm)

    quote do
      Kernel.def(unquote(sig), unquote(body))
    end
  end
end
