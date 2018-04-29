defmodule KV.Registry do
  @moduledoc false
  use GenServer

  # Client API

  @doc """
  Starts the registry
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid by `name`.
  Returns `{:ok, pid}` or {:error} if doesn't exist.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Associate bucket to a `name`
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  @doc """
  Stop the registry
  """
  def stop(server) do
    GenServer.stop(server)
  end

  # Server Callbacks

  def init(:ok) do
    names = %{}
    # for monitoring
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {names, _refs} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      # Note this link here will cause the registry to crash
      # If the bucket crashes unless we trap exists.  Also,
      # Its better to delegate start_link and monitoring to
      # Supervisors
      {:ok, bucket} = KV.Bucket.start_link([])
      ref   = Process.monitor(bucket)
      refs  = Map.put(names, name, bucket)
      names = Map.put(refs, name, ref)
      {:noreply, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  # Ignore all other messages from monitored bucket
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
