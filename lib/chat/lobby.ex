defmodule Chat.GenLobby do
  use GenServer

  alias Chat.GenRoom

  def start_link(_), do:
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def get_rooms(), do: GenServer.call(__MODULE__, :get_rooms)

  def create_room(room_name), do:
    GenServer.call(__MODULE__, {:create_room, room_name})

  def subscribe(lv_pid), do:
    GenServer.cast(__MODULE__, {:subscribe, lv_pid})

  # Callbacks

  @impl true
  def init(_state) do
    {:ok,
      %{
        rooms: [],
        liveview_pids: []
      },
      :infinity
    }
  end

  @impl true
  def handle_call(:get_rooms, _, state), do: {:reply, state.rooms, state}

  def handle_call({:create_room, room_name}, _, state) do
    case GenRoom.start(room_name) do
      {:already_started, _room_pid} ->
        {:reply, {:already_started, state.rooms}, state}

      {:ok, room_pid} ->
        new_rooms =
          [{room_name, room_pid} | state.rooms]

        Enum.each(state.liveview_pids, &send(&1, {:update_rooms, new_rooms}))

        {:reply, {:ok, new_rooms}, %{state | rooms: new_rooms}}
    end
  end

  @impl true
  def handle_cast({:subscribe, lv_pid}, state) do
    if Enum.member?(state.liveview_pids, lv_pid) do
      {:noreply, state}
    else
      {:noreply, %{state | liveview_pids: [lv_pid | state.liveview_pids]}}
    end
  end
end
