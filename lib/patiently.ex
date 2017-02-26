defmodule Patiently do
  @moduledoc File.read!(Path.expand("../README.md", __DIR__))

  @type condition :: (() -> boolean)
  @type opt :: {:dwell, pos_integer} | {:max_tries, pos_integer}
  @type opts :: [opt]

  defmodule GaveUp do
    @moduledoc """
    Exception raised by Patiently when a condition fails to converge
    """

    defexception message: nil
    @type t :: %__MODULE__{__exception__: true}

    @doc false
    @spec exception({pos_integer, pos_integer, Patiently.condition}) :: t
    def exception({dwell, max_tries, condition}) do
      message = "Gave waiting for #{inspect condition} after #{max_tries} " <>
        "iterations waiting #{dwell} msec between tries."
      %Patiently.GaveUp{message: message}
    end
  end

  @default_dwell 100
  @default_tries 10

  @spec wait_for(condition, opts) :: :ok | :error
  def wait_for(condition, opts \\ []) do
    wait_while(condition, &(!&1), opts)
  end

  @spec wait_for!(condition, opts) :: :ok | no_return
  def wait_for!(condition, opts \\ []) do
    case wait_for(condition, opts) do
      :ok -> :ok
      :error ->
        raise Patiently.GaveUp, {dwell(opts), max_tries(opts), condition}
    end
  end

  defp wait_while(poller, condition, opts) do
    wait_while_loop(poller, condition, 0, opts)
  end

  defp wait_while_loop(poller, condition, tries, opts) do
    value = poller.()
    if condition.(value) do
      if tries > max_tries(opts) do
        :error
      else
        :timer.sleep(dwell(opts))
        wait_while_loop(poller, condition, tries + 1, opts)
      end
    else
      :ok
    end
  end

  defp dwell(opts) do
    Keyword.get(opts, :dwell, @default_dwell)
  end

  defp max_tries(opts) do
    Keyword.get(opts, :max_tries, @default_tries)
  end
end
