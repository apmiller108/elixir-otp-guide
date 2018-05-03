defmodule KV do
  @moduledoc false
  use Application

  def start(_type, _args) do
    KV.Supervisor.start_link(name: KV.Supervisor)
  end
end
