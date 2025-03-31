defmodule AbrechnomatBot.TaskPoolTest do
  use ExUnit.Case, async: true
  alias AbrechnomatBot.TaskPool

  test "can run a task" do
    %{TaskPool.init() | max_tasks: 3}
    |> TaskPool.run_or_queue(fn -> :first_task_executed end)

    assert_receive {_, :first_task_executed}, 100
  end

  test "immediately runs task up to max task limit" do
    %{TaskPool.init() | max_tasks: 3}
    |> TaskPool.run_or_queue(fn -> :first_task_executed end)
    |> TaskPool.run_or_queue(fn -> :second_task_executed end)
    |> TaskPool.run_or_queue(fn -> :third_task_executed end)
    |> TaskPool.run_or_queue(fn -> :queued end)

    assert_receive {_, :first_task_executed}, 100
    assert_receive {_, :second_task_executed}, 100
    assert_receive {_, :third_task_executed}, 100
    refute_receive {_, :queued}, 100
  end

  test "executes other tasks if one throws" do
    %{TaskPool.init() | max_tasks: 3}
    |> TaskPool.run_or_queue(fn -> raise "Something happened" end)
    |> TaskPool.run_or_queue(fn -> :second_task_executed end)

    assert_receive {_, :second_task_executed}, 100
  end

  test "can replace a task with one from the queue" do
    pool =
      %{TaskPool.init() | max_tasks: 1}
      |> TaskPool.run_or_queue(fn -> :first_task_executed end)
      |> TaskPool.run_or_queue(fn -> :second_task_executed end)

    assert_receive {_, :first_task_executed}, 100
    refute_receive {_, :second_task_executed}, 100

    task_pid =
      receive do
        {:DOWN, _ref, :process, pid, :normal} -> pid
      after
        100 -> flunk("first task did not exit")
      end

    pool = TaskPool.run_queued_tasks(pool, {:replace, task_pid})

    assert_receive {_, :second_task_executed}, 100
    assert pool.tasks[task_pid] == nil
  end
end
