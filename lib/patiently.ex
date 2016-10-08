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
    {dwell, max_tries} = process_opts(opts)
    wait_loop(condition, dwell, 0, max_tries)
  end

  def wait_for!(condition, opts \\ []) do
    {dwell, max_tries} = process_opts(opts)
    case wait_for(condition, opts) do
      :ok -> :ok
     :error -> raise Patiently.GaveUp, {dwell, max_tries, condition}
    end
  end

  defp wait_loop(condition, dwell, tries, max_tries) when tries >= max_tries do
    :error
  end
  defp wait_loop(condition, dwell, tries, max_tries) do
    if condition.() do
      :ok
    else
      :timer.sleep(dwell)
      wait_loop(condition, dwell, tries + 1, max_tries)
    end
  end

  defp process_opts(opts) do
    {
      Keyword.get(opts, :dwell, @default_dwell),
      Keyword.get(opts, :max_tries, @default_tries)
    }
  end
end
