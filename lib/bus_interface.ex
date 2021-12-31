defmodule RtlSdrHomebridge.BusInterface do
  @moduledoc """
  Interface to the messaging bus between the RTL-SDR and Homebridge
  """
  use GenServer
  use QolUp.LoggerUtils

  ##############################
  # API
  ##############################

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

  ##############################
  # Internal Calls
  ##############################
end
