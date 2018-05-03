defmodule KV.Supervisor do
  @moduledoc false
  use Supervisor

  # Client

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  # Server

  def init(:ok) do
    # Once the supervisor starts, it will traverse the list of
    # children and it will invoke the child_spec/1 function on each module.
    # Children are started in the order listed.
    children = [
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {KV.Registry, name: KV.Registry}
    ]
    # This will call KV.Registry.start_link([name: KV.Registry])
    # thus starting the supervised process automatically
    Supervisor.init(children, strategy: :one_for_all)
  end
end
