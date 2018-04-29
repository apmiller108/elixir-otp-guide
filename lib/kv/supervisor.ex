defmodule KV.Supervisor do
  @moduledoc false
  use Supervisor

  # Client

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  # Server

  def init(:ok) do
    children = [{KV.Registry, name: KV.Registry}]
    # This will call KV.Registry.start_link([name: KV.Registry])
    Supervisor.init(children, strategy: :one_for_one)
  end
end
