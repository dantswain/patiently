defmodule Patiently do
  @moduledoc File.read!(Path.expand("../README.md", __DIR__))

  @type iteration :: (() -> term)
  @type predicate :: ((term) -> boolean)
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
    @spec exception({pos_integer, pos_integer}) :: t
    def exception({dwell, max_tries}) do
      message = "Gave up waiting for condition after #{max_tries} " <>
        "iterations waiting #{dwell} msec between tries."
      %Patiently.GaveUp{message: message}
    end
  end

  @default_dwell 100
  @default_tries 10

  @spec wait_for(condition, opts) :: :ok | :error
  def wait_for(condition, opts \\ []) do
    wait_while(condition, &(&1), opts)
  end

  @spec wait_for!(condition, opts) :: :ok | no_return
  def wait_for!(condition, opts \\ []) do
    ok_or_raise(wait_for(condition, opts), opts)
  end

  @spec wait_for(iteration, predicate, opts) :: :ok | :error
  def wait_for(iteration, condition, opts) do
    wait_while(iteration, condition, opts)
  end

  @spec wait_for!(iteration, predicate, opts) :: :ok | no_return
  def wait_for!(iteration, condition, opts) do
    ok_or_raise(wait_for(iteration, condition, opts), opts)
  end

  defp ok_or_raise(:ok, _), do: :ok
  defp ok_or_raise(:error, opts) do
    raise Patiently.GaveUp, {dwell(opts), max_tries(opts)}
  end

  defp wait_while(poller, condition, opts) do
    wait_while_loop(poller, condition, 0, opts)
  end

  defp wait_while_loop(poller, condition, tries, opts) do
    value = poller.()
    if condition.(value) do
      :ok
    else
      if tries > max_tries(opts) do
        :error
      else
        :timer.sleep(dwell(opts))
        wait_while_loop(poller, condition, tries + 1, opts)
      end
    end
  end

  defp dwell(opts) do
    Keyword.get(opts, :dwell, @default_dwell)
  end

  defp max_tries(opts) do
    Keyword.get(opts, :max_tries, @default_tries)
  end
end
