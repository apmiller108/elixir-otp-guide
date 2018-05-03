defmodule KV.Bucket do
  @moduledoc false
  use Agent, restart: :temporary

  def start_link(_options) do
    Agent.start_link(fn -> %{} end)
  end

  def get(bucket, key) do
    Agent.get(bucket, fn state -> Map.get(state, key) end)
  end

  def put(bucket, key, value) do
    Agent.update(
      bucket,
      fn(state) -> Map.put(state, key, value) end
    )
  end

  @doc """
  Deletes `key` from `bucket`.

  Returns the current value of `key`, if `key` exists.
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, &Map.pop(&1, key))
  end
end
