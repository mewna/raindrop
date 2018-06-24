defmodule Raindrop.Generator do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link __MODULE__, opts, name: __MODULE__
  end

  # TODO: Actually have opts?
  def init(opts) do
    state = %{epoch: opts[:epoch], seqnum: 0, worker_id: nil}
    Process.send_after self(), :get_new_id, 1000
    Logger.info "Will start searching for worker id in 1000ms"
    {:ok, state}
  end

  # API

  def gen_drop do
    GenServer.call __MODULE__, :gen_drop
  end

  def get_worker_id do
    pid = Process.whereis __MODULE__
    if pid do
      GenServer.call __MODULE__, :get_id
    else
      nil
    end
  end

  def handle_call(:get_id, _from, state) do
    {:reply, state[:worker_id], state}
  end

  def handle_call(:gen_drop, _from, state) do
    if state[:worker_id] do
      drop = create_drop state[:epoch], :os.system_time(:millisecond), state[:worker_id], state[:seqnum]
      new_seq = if state[:seqnum] >= 4095 do
                  0
                else
                  state[:seqnum] + 1
                end
      {:reply, drop, %{state | seqnum: new_seq}}
    else
      {:reply, nil, state}
    end
  end

  def handle_info(:get_new_id, state) do
    id = get_new_id Node.list, :rand.uniform(2014) - 1, false, 0
    Logger.info "Assigning self to id #{id} (checked #{length(Node.list())} nodes)"
    {:noreply, %{state | worker_id: id}}
  end

  defp get_new_id([head | tail] = _nodes, id, needs_new, times) do
    task = Task.Supervisor.async({Raindrop.Tasks, head}, __MODULE__, :get_worker_id, [])
    node_id = Task.await task
    needs_new = unless needs_new do
                  node_id == id
                else
                  true
                end
    # ID taken -> immediately reject and start over
    if needs_new do
      get_new_id [], id, true, times + 1
    else
      get_new_id tail, id, needs_new, times + 1
    end
  end

  defp get_new_id([], id, needs_new, times) do
    # [0, 1024)
    if times == 0 do
      :rand.uniform(1024) - 1
    else 
      if needs_new do
        Logger.warn "Rejected id #{id}"
        get_new_id Node.list, :rand.uniform(1024) - 1, false, times + 1
      else
        id
      end
    end
  end

  # Testable API

  def create_drop(epoch, timestamp, worker_id, seqnum) when is_integer(epoch) and is_integer(timestamp) and is_integer(worker_id) do
    final_ts = timestamp - epoch
    << 0::1, final_ts::41, worker_id::10, seqnum::12 >>
  end
end