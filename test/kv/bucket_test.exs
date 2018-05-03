defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  # Setup callback runs before the test in the same process
  setup do
    bucket = start_supervised!(KV.Bucket)
    %{bucket: bucket}
  end

  # Pattern match on bucket from the callback result to use it in the test
  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "deletes values by key", %{bucket: bucket} do
    assert KV.Bucket.delete(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.delete(bucket, "milk") == 3
  end

  test 'are temporary workers' do
    assert Supervisor.child_spec(KV.Bucket, []).restart == :temporary
  end
end
