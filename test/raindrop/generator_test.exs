defmodule GeneratorTest do
  use ExUnit.Case
  doctest Raindrop.Generator

  test "generates valid snowflake" do
    epoch = 1518566400000
    timestamp = :os.system_time :millisecond
    worker_id = 512
    seq = 2048
    snowflake = Raindrop.Generator.create_drop epoch, timestamp, worker_id, seq

    << _sign::1, s_time::41, s_worker::10, s_seq::12 >> = snowflake
    assert s_time == timestamp - epoch
    assert s_time + epoch == timestamp # lol
    assert s_worker == worker_id
    assert s_seq == seq
  end
end