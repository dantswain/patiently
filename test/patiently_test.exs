defmodule PatientlyTest do
  use ExUnit.Case
  doctest Patiently

  defmodule Irritable do
    def start(callback) do
      Agent.start(fn -> %{callback: callback, iteration: 0} end)
    end

    def stop(pid), do: Agent.stop(pid)

    def reset(pid) do
      Agent.update(pid, fn(state) -> %{state | iteration: 0} end)
    end

    def iterate(pid) do
      Agent.get_and_update(
        pid,
        fn(state) ->
          result = state.callback.(state.iteration)
          {
            result,
            %{state | iteration: state.iteration + 1}
          }
        end
      )
    end
  end

  test "waiting without an exception" do
    tries = 5
    {:ok, irritable} = Irritable.start(
      fn(iteration) -> iteration > tries end
    )

    f = fn -> Irritable.iterate(irritable) end
    assert :ok == Patiently.wait_for(f, dwell: 10)

    Irritable.reset(irritable)
    assert :error == Patiently.wait_for(f, max_tries: tries - 1, dwell: 10)
    Irritable.reset(irritable)
    assert_raise Patiently.GaveUp, fn ->
      Patiently.wait_for!(f, max_tries: tries - 1, dwell: 10)
    end

    Irritable.stop(irritable)
  end

  test "waiting with condition and predicate" do
    tries = 5
    {:ok, irritable} = Irritable.start(
      fn(iteration) -> iteration end
    )

    f = fn -> Irritable.iterate(irritable) end
    p = fn(v) -> v > tries end
    assert :ok == Patiently.wait_for(f, p, dwell: 10)

    Irritable.reset(irritable)
    assert :error == Patiently.wait_for(f, p, max_tries: tries - 1, dwell: 10)
    Irritable.reset(irritable)
    assert_raise Patiently.GaveUp, fn ->
      Patiently.wait_for!(f, p, max_tries: tries - 1, dwell: 10)
    end

    Irritable.stop(irritable)
  end

  test "waiting with a reducer" do
    tries = 5
    expected_acc = Enum.into(tries..0, [])
    expected_error_acc = Enum.into(tries-1..0, [])

    r = fn(acc) -> [length(acc) | acc] end
    p = fn(acc) -> length(acc) > tries end
    assert {:ok, expected_acc} == Patiently.wait_reduce(r, p, [], dwell: 10)
    assert {:error, expected_error_acc} ==
      Patiently.wait_reduce(r, p, [], max_tries: tries - 1, dwell: 10)

    assert {:ok, expected_acc} == Patiently.wait_reduce!(r, p, [], dwell: 10)
    assert_raise Patiently.GaveUp, fn ->
      Patiently.wait_reduce!(r, p, [], max_tries: tries - 1, dwell: 10)
    end
  end

  test "waiting with flat list" do
    tries = 5
    expected_acc = List.flatten(List.duplicate([1, 2, 3], (tries + 1)))
    expected_error_acc = List.flatten(List.duplicate([1, 2, 3], tries))
    min_length = 3 * tries + 1

    f = fn() -> [1, 2, 3] end
    p = fn(acc) -> length(acc) > 3 * tries end
    assert {:ok, expected_acc} == Patiently.wait_flatten(f, p, dwell: 10)
    assert {:ok, expected_acc} == Patiently.wait_flatten(f, min_length, dwell: 10)
    assert {:error, expected_error_acc} ==
      Patiently.wait_flatten(f, p, max_tries: tries - 1, dwell: 10)
    assert {:error, expected_error_acc} ==
      Patiently.wait_flatten(f, min_length, max_tries: tries - 1, dwell: 10)

    assert {:ok, expected_acc} == Patiently.wait_flatten!(f, p, dwell: 10)
    assert {:ok, expected_acc} == Patiently.wait_flatten!(f, min_length, dwell: 10)
    assert_raise Patiently.GaveUp, fn ->
      Patiently.wait_flatten!(f, p, max_tries: tries - 1, dwell: 10)
    end
    assert_raise Patiently.GaveUp, fn ->
      Patiently.wait_flatten!(f, min_length, max_tries: tries - 1, dwell: 10)
    end
  end

  test "waiting with flat list (scalar result)" do
    tries = 5
    expected_acc = List.duplicate("foo", (tries + 1))
    expected_error_acc = List.duplicate("foo", tries)
    min_length = tries + 1

    f = fn() -> "foo" end
    p = fn(acc) -> length(acc) > tries end
    assert {:ok, expected_acc} == Patiently.wait_flatten(f, p, dwell: 10)
    assert {:ok, expected_acc} == Patiently.wait_flatten(f, min_length, dwell: 10)
    assert {:error, expected_error_acc} ==
      Patiently.wait_flatten(f, p, max_tries: tries - 1, dwell: 10)
    assert {:error, expected_error_acc} ==
      Patiently.wait_flatten(f, min_length, max_tries: tries - 1, dwell: 10)

    assert {:ok, expected_acc} == Patiently.wait_flatten!(f, p, dwell: 10)
    assert {:ok, expected_acc} == Patiently.wait_flatten!(f, min_length, dwell: 10)
    assert_raise Patiently.GaveUp, fn ->
      Patiently.wait_flatten!(f, p, max_tries: tries - 1, dwell: 10)
    end
    assert_raise Patiently.GaveUp, fn ->
      Patiently.wait_flatten!(f, min_length, max_tries: tries - 1, dwell: 10)
    end
  end

  test "waiting for a process to die" do
    pid = spawn(fn -> :timer.sleep(20) end)
    assert :ok == Patiently.wait_for_death(pid, dwell: 10)

    pid = spawn(fn -> :timer.sleep(1000) end)
    assert :error == Patiently.wait_for_death(pid, dwell: 10)

    pid = spawn(fn -> :timer.sleep(20) end)
    assert :ok == Patiently.wait_for_death!(pid, dwell: 10)

    pid = spawn(fn -> :timer.sleep(1000) end)
    assert_raise Patiently.GaveUp, fn -> Patiently.wait_for_death!(pid, dwell: 10) end
  end
end
