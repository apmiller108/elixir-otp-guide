defmodule KV.Registry do
  @moduledoc false
  use GenServer

  # Client API

  @doc """
  Starts the registry with options

  `:name` is required
  """
  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, opts)
  end

  @doc """
  Looks up the bucket pid by `name` in ETS table
  Returns `{:ok, pid}` or {:error} if doesn't exist.
  """
  def lookup(server, name) do
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @doc """
  List the buckets
  """
  def index(server) do
    :ets.match(server, {:"$1", :"$2"})
  end

  @doc """
  Associate bucket to a `name`
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  @doc """
  Stop the registry
  """
  def stop(server) do
    GenServer.stop(server)
  end

  # Server Callbacks

  def init(table_name) do
    names_table = :ets.new(table_name, [:named_table, read_concurrency: true])
    # for monitoring
    refs = %{}
    {:ok, {names_table, refs}}
  end

  def handle_call({:create, name}, _from, {names_table, refs}) do
    case lookup(names_table, name) do
      {:ok, pid} -> {:reply, pid, {names_table, refs}}
      :error ->
        # Note using start_link here will cause the registry to crash
        # if the bucket crashes unless we trap exists. Thus,
        # Its better to delegate start_link and monitoring to
        # Supervisors
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
          ref         = Process.monitor(pid)
          refs        = Map.put(refs, ref, name)
          :ets.insert(names_table, {name, pid})
          {:reply, pid, {names_table, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names_table, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names_table, name)
    {:noreply, {names_table, refs}}
  end

  # Ignore all other messages from monitored bucket
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
