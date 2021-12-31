defmodule RtlSdrHomebridge do
  @moduledoc """
  Documentation for `RtlSdrHomebridge`.
  """
  use Application
  use QolUp.LoggerUtils

  def start(_type, _args) do
    children = []
    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
