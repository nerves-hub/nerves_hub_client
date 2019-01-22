defmodule NervesHub.Supervisor do
  use Supervisor

  alias NervesHub.Channel.{Config, Socket, FirmwareChannel}

  @moduledoc """
  Supervisor for maintaining a channel connection to a NervesHub server

  This module starts the GenServers that maintain a Phoenix channel connection
  to the NervesHub server and respond to update requests.  It isn't started
  automatically, so you should add it to one of your OTP application's
  supervision trees:

  ```elixir
    defmodule Example.Application do
      use Application

      def start(_type, _args) do

        opts = [strategy: :one_for_one, name: Example.Supervisor]
        children = [
          NervesHub.Supervisor
        ] ++ children(@target)
        Supervisor.start_link(children, opts)
      end
    end
  ```
  """

  @doc """
  Start the NervesHub supervision tree

  Options:

  * `client` - Behaviour for handling firmware update events (defaults to `NervesHub.Client.Default`)
  * `device_host` - Hostname or IP address of NervesHub server's endpoint that handling devices (default is "device.nerves-hub.org")
  * `device_port` - Port number to use to connect to server (default is port 443)
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    case Supervisor.start_link(__MODULE__, opts, name: __MODULE__) do
      {:ok, pid} ->
        NervesHub.connect()
        {:ok, pid}

      error ->
        error
    end
  end

  @impl true
  def init(opts) do
    socket_opts = Config.derive_unspecified_options(opts)

    children = [
      {Socket, socket_opts},
      {FirmwareChannel,
       {[socket: Socket, topic: FirmwareChannel.topic()], [name: FirmwareChannel]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
