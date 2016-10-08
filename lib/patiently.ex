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

  def wait_for(
        condition,
        dwell \\ @default_dwell,
        max_tries \\ @default_tries)
  when is_integer(dwell) and dwell >= 0
  and is_integer(max_tries) and max_tries > 0 do
    wait_loop(condition, dwell, 0, max_tries)
  end

  def wait_for!(condition, dwell \\ @default_dwell, max_tries \\ @default_tries) do
    case wait_for(condition, dwell, max_tries) do
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
end
