defmodule RtlSdrHomebridge.BusInterface do
  @moduledoc """
  Interface to the messaging bus between the RTL-SDR and Homebridge. Message field transformation happens here.
  """
  use GenServer
  use QolUp.LoggerUtils

  @type ok_or_err :: :ok | {:error, any()}

  ##############################
  # API
  ##############################

  @spec pub_zone_state(non_neg_integer(), String.t(), integer(), integer()) :: ok_or_err()
  @doc """
  Publish a zone state update
  ## Parameters
  - `zone_id` The zone id (e.g. 125008)
  - `zone_state` The zone state (e.g. "closed")
  - `zone_tamper` The zone tamper status (e.g. 1 for tamper, 0 for not tampered)
  - `zone_battery_ok` The battery ok status (e.g. 1 for ok, 0 for battery not ok)
  """
  def pub_zone_state(zone_id, zone_state, zone_tamper, zone_battery_ok),
    do: GenServer.call(__MODULE__, {:pub_zone_state, zone_id, zone_state, zone_tamper, zone_battery_ok})

  @doc """
  Start the worker
  """
  @spec start_link(:ok) :: GenServer.on_start()
  def start_link(:ok), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  defmodule State do
    @moduledoc false
    @keys ~w//a
    @enforce_keys @keys
    defstruct @keys

    @type t() :: %__MODULE__{}
  end

  ##############################
  # GenServer Callbacks
  ##############################

  @impl GenServer
  def init(:ok) do
    L.info("Starting")
    {:ok, %State{}}
  end

  @impl GenServer
  def handle_call({:pub_zone_state, zone_id, zone_state, zone_tamper, zone_battery_ok}, _from, state) do
    {updated_state, result} = do_pub_zone_state(state, zone_id, zone_state, zone_tamper, zone_battery_ok)
    {:reply, result, updated_state}
  end

  ##############################
  # Internal Calls
  ##############################

  @spec do_pub_zone_state(State.t(), non_neg_integer(), String.t(), integer(), integer()) :: {State.t(), ok_or_err()}
  @doc false
  def do_pub_zone_state(state, zone_id, zone_state, zone_tamper, zone_battery_ok) do
    L.locals()
    {state, :ok}
  end
end
