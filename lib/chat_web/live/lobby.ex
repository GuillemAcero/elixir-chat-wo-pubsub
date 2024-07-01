defmodule ChatWeb.ChatLive.Lobby do
  use ChatWeb, :live_view

  alias Chat.GenLobby

  @impl true
  def mount(_params,  _, socket) do
    GenLobby.subscribe(self())
    rooms = GenLobby.get_rooms()

    {:ok,
      socket
      |> assign(:rooms, rooms)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center text-4xl justify-center">
        LOBBY
      </div>
      <%= for {room_id, _pid} <- Enum.reverse(@rooms) do %>
        <div class="text-2xl mb-1 hover:underline">
          <.link target="_blank" href={~p"/room/#{room_id}"}> <%= room_id %></.link>
        </div>
      <% end %>

      <form phx-submit="add-room" class="mt-5">
        <div class="w-full grid grid-cols-10 gap-1">
          <input name="room-id" id="room-id" class="col-span-8 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6" type="text" required />
          <.button class="w-full col-span-2">+ Add room</.button>
        </div>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("add-room", %{"room-id" => room_id}, socket) do
    case GenLobby.create_room(room_id) do
      {:already_started, rooms} ->
        {:noreply, assign(socket, :rooms, rooms)}

      {:ok, rooms} ->
        {:noreply, assign(socket, :rooms, rooms)}
    end
  end

  @impl true
  def handle_info({:update_rooms, rooms}, socket) do
    {:noreply, assign(socket, :rooms, rooms)}
  end
end
