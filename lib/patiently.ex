defmodule Patiently do
  defmodule GaveUp do
    defexception [:message]

    def exception({dwell, max_tries, condition}) do
      message = "Gave waiting for #{inspect condition} after #{max_tries} " <>
        "iterations waiting #{dwell} msec between tries."
      %Patiently.GaveUp{
        message: message
      }
    end
  end

  @default_dwell 100
  @default_tries 10

  def wait_for(condition, opts \\ []) do
    wait_while(condition, &(!&1), opts)
  end

  def wait_for!(condition, opts \\ []) do
    case wait_for(condition, opts) do
      :ok -> :ok
      :error -> raise Patiently.GaveUp, {dwell(opts), max_tries(opts), condition}
    end
  end

  def wait_while(poller, condition, opts \\ []) do
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

  def generic_loop(poller, condition, state, opts) do
    state_out = poller.(state)
  end

  defp dwell(opts) do
    Keyword.get(opts, :dwell, @default_dwell)
  end

  defp max_tries(opts) do
    Keyword.get(opts, :max_tries, @default_tries)
  end
end
