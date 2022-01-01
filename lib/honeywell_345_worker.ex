defmodule RtlSdrHomebridge.Honeywell345.Worker do
  @moduledoc """
   Honeywell 345 worker; listens on a rtl-sdr for honeywell
   345MHz messages and publishes them. This uses the rtl_433 program (see README.md) to interface with the radio.

   rtl_433 example output from honeywell `rtl_433 -f 344940000 -F json -R 70`:
   ```json
   {"time" : "2021-03-20 11:47:16", "model" : "Honeywell-Security", "id" : 125008, "channel" : 8, "event" : 52, "state" : "closed", "contact_open" : 0, "reed_open" : 1, "alarm" : 1, "tamper" : 0, "battery_ok" : 1, "heartbeat" : 1}
   ```
  """

  use GenServer
  use QolUp.LoggerUtils

  ##############################
  # API
  ##############################

  @doc """
  Start the worker
  ## Parameters
  - ndx The index of the rtl-sdr radio to use; this depends on the order of
    radios returned from `System.cmd("lsusb", ["-d", "0BDA:2838"])`
  """
  @spec start_link(non_neg_integer()) :: GenServer.on_start()
  def start_link(ndx), do: GenServer.start_link(__MODULE__, ndx, name: String.to_atom("#{__MODULE__}-#{ndx}"))

  defmodule State do
    @moduledoc false
    @keys ~w/ndx pid stdout_lb/a
    @enforce_keys @keys
    defstruct @keys

    @type t() :: %__MODULE__{
            ndx: non_neg_integer(),
            pid: pid() | nil,
            stdout_lb: LineBuffer.State.t()
          }
  end

  ##############################
  # GenServer Callbacks
  ##############################

  @impl GenServer
  def init(ndx) do
    L.info("Starting (ndx: #{ndx})")
    send(self(), :init_radio)
    {:ok, %State{pid: nil, ndx: ndx, stdout_lb: LineBuffer.new()}}
  end

  @impl GenServer
  def handle_info(:init_radio, %State{ndx: ndx} = state) do
    updated_state =
      case Executus.execute("rtl_433 -d #{ndx} -f 344940000 -F json -R 70", sync: false) do
        {:ok, pid} ->
          L.info("Launched rtl_433 with pid: #{inspect(pid, pretty: true)}")
          %State{state | pid: pid, stdout_lb: LineBuffer.new()}

        error ->
          L.info("Failed to launch rtl_433: #{inspect(error, pretty: true)}")
          Process.send_after(self(), :init_radio, 5_000)
          state
      end

    {:noreply, updated_state}
  end

  @impl GenServer
  def handle_info({_pid, :data, :out, data}, state) do
    {:noreply, do_handle_stdout(state, data)}
  end

  @impl GenServer
  def handle_info({_pid, :data, :err, data}, state) do
    {:noreply, do_handle_stderr(state, data)}
  end

  @impl GenServer
  def handle_info({dead_pid, :result, result}, state) do
    L.info("Pid #{inspect(dead_pid)} exited: #{inspect(result, pretty: true)}")
    # Process.send_after(self(), :init_radio, 5_000)
    {:noreply, %State{state | pid: nil}}
  end

  ##############################
  # Internal Calls
  ##############################

  @spec do_handle_stdout(State.t(), binary()) :: State.t()
  @doc false
  def do_handle_stdout(%State{stdout_lb: stdout_lb} = state, data) do
    L.debug("rtl_433 reports: #{inspect(data, pretty: true)}")
    {updated_stdout_lb, lines} = LineBuffer.add_data(stdout_lb, data)
    process_lines(%State{state | stdout_lb: updated_stdout_lb}, lines)
  end

  @spec do_handle_stderr(State.t(), binary()) :: State.t()
  @doc false
  def do_handle_stderr(state, data) do
    L.debug("rtl_433 is whining: #{inspect(data, pretty: true)}")
    state
  end

  @spec process_lines(State.t(), list(binary())) :: State.t()
  @doc false
  def process_lines(state, lines)

  def process_lines(state, []), do: state

  def process_lines(state, [line | rest]) do
    with {:ok, zone_msg} <- JSON.decode(line),
         {:ok, zone_id} <- Map.fetch(zone_msg, "id"),
         {:ok, zone_state} <- Map.fetch(zone_msg, "state"),
         {:ok, zone_tamper} <- Map.fetch(zone_msg, "tamper"),
         {:ok, zone_battery_ok} <- Map.fetch(zone_msg, "battery_ok") do
      RtlSdrHomebridge.BusInterface.pub_zone_state(zone_id, zone_state, zone_tamper, zone_battery_ok)
    else
      error ->
        L.debug("Error: #{inspect(error, pretty: true)} parsing: #{inspect(line, pretty: true)}")
    end

    process_lines(state, rest)
  end
end
