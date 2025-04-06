defmodule AbrechnomatBot.TaskPool do
  defstruct [:tasks, :queue, :max_tasks]

  defmodule Supervisor do
    def child_spec(args) do
      name = __MODULE__

      %{
        id: name,
        start: {
          Task.Supervisor,
          :start_link,
          [Keyword.merge(args, name: name)]
        },
        type: :supervisor,
        modules: [__MODULE__]
      }
    end
  end

  def init(),
    do: %__MODULE__{
      tasks: %{},
      queue: :queue.new(),
      max_tasks: System.schedulers_online()
    }

  def run_or_queue(pool, task_fn) do
    if can_run_more?(pool) do
      new_tasks = run_task(pool.tasks, task_fn)
      %{pool | tasks: new_tasks}
    else
      new_queue = :queue.in(task_fn, pool.queue)
      %{pool | queue: new_queue}
    end
  end

  def run_queued_tasks(%__MODULE__{tasks: tasks} = pool, {:replace, pid}) do
    clean_tasks = Map.delete(tasks, pid)
    run_queued_tasks(%{pool | tasks: clean_tasks})
  end

  def run_queued_tasks(%__MODULE__{tasks: tasks, queue: queue} = pool) do
    {popped, new_queue} = :queue.out(queue)

    case popped do
      :empty ->
        pool

      {:value, task_fn} ->
        %{pool | tasks: run_task(tasks, task_fn), queue: new_queue}
    end
  end

  defp run_task(tasks, task_fn) do
    task = Task.Supervisor.async(Supervisor, task_fn)
    Map.put(tasks, task.pid, task)
  end

  defp can_run_more?(pool) do
    length(Map.keys(pool.tasks)) < pool.max_tasks
  end
end
