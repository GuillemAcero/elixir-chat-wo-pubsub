defmodule ChatWeb.ChatLive.Room do
  use ChatWeb, :live_view

  alias Chat.{GenRoom, Message}

  @impl true
  def mount(%{"room_id" => room_id},  _, socket) do
    if connected?(socket) do
      msg = Message.new(:join, socket.assigns.current_user, DateTime.now!("Etc/UTC"))
      GenRoom.new_message(room_id, msg)
      GenRoom.subscribe(room_id, socket.assigns.current_user, self())
    end

    room = GenRoom.get_room_info(room_id)

    {:ok,
      socket
      |> assign(room_id: room_id)
      |> assign(messages: room.messages)
      |> assign(connected_users: room.connected_users)
      |> assign(users_to_notify: [])
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center text-4xl">
        <%= @room_id %>
      </div>

      <div class="w-full grid grid-cols-10 gap-2">
        <div class="col-span-8 border rounded-md h-96 p-3 overflow-y-auto">
          <%= for message <- Enum.reverse(@messages) do %>
            <.message message={message} current_user={@current_user} />
          <% end %>
        </div>
        <div class="col-span-2 border rounded-md h-96 px-4 py-3 overflow-y-auto">
          <%= for user <- Enum.reject(@connected_users, & &1 == @current_user) do %>
            <div phx-click="private-chat" phx-value-chat-with={user} class="items-center border rounded-md bg-blue-200 mb-2 px-2 py-2 hover:cursor-pointer">
              <p><%= user %></p>
              <p :if={Enum.member?(@users_to_notify, user)} class="text-xs">Want to chat!</p>
            </div>
          <% end %>
        </div>
      </div>

      <form phx-submit="add-message" class="mt-5">
        <div class="w-full grid grid-cols-10 gap-2">
          <input name="message" id="message" class="col-span-8 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6" type="text" required />
          <.button class="w-full col-span-2">Send ></.button>
        </div>
      </form>

      <script>
        window.addEventListener("phx:open_private_chat", (event) => {
          window.open(event.detail.url, "_blank");
        });
      </script>
    </div>
    """
  end

  def message(%{message: %{action: :join}} = assigns) do
    ~H"""
    <div class="w-full flex items-center justify-center text-gray-400">
      <%= "-- #{@message.user_id} joined the room --" %>
    </div>
    """
  end

  def message(%{message: %{action: :left}} = assigns) do
    ~H"""
    <div class="w-full flex items-center justify-center text-gray-400">
      <%= "-- #{@message.user_id} left the room --" %>
    </div>
    """
  end

  def message(%{message: %{user_id: user_id}, current_user: user} = assigns) when user == user_id do
    ~H"""
    <div class="flex justify-end my-1">
      <div class="rounded-lg bg-green-100 text-gray-800 px-3 py-1">
        <p class="text-gray-900 text-xs"><%= @message.user_id %></p>
        <p class="text-gray-700"><%= @message.message %></p>
      </div>
    </div>
    """
  end

  def message(assigns) do
    ~H"""
    <div class="flex justify-start my-1">
      <div class="rounded-lg bg-gray-100 px-3 py-1">
        <p class="text-gray-900 text-xs"><%= @message.user_id %></p>
        <p class="text-gray-700"><%= @message.message %></p>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("add-message", %{"message" => msg}, socket) do
    new_message =
      Message.new(:msg, socket.assigns.current_user, DateTime.now!("Etc/UTC"), msg)

    GenRoom.new_message(socket.assigns.room_id, new_message)

    {:noreply, socket}
  end

  def handle_event("private-chat", %{"chat-with" => chat_with}, socket) do
    chat_id = Chat.generate_chat_id(chat_with, socket.assigns.current_user)

    socket = assign(socket, :users_to_notify, Enum.reject(socket.assigns.users_to_notify, & &1 == chat_with))

    case GenRoom.start({:chat, chat_id}) do
      {:already_started, _pid} ->
        {:noreply,
          socket
          |> redirect(to: ~p"/private_chat/#{chat_id}")
        }

      {:ok, _pid} ->
        GenRoom.notify_new_chat(socket.assigns.room_id, socket.assigns.current_user, chat_with)

        {:noreply, push_event(socket, "open_private_chat", %{url: ~p"/private_chat/#{chat_id}"})}
    end
  end

  @impl true
  def handle_info({:update_messages, messages}, socket) do
    {:noreply, assign(socket, :messages, messages)}
  end

  def handle_info({:update_connected_users, users}, socket) do
    {:noreply, assign(socket, :connected_users, users)}
  end

  def handle_info({:new_private_chat, user}, socket) do

    {:noreply, assign(socket, :users_to_notify, [user | socket.assigns.users_to_notify])}
  end

  @impl true
  def terminate(_reason, socket) do
    GenRoom.disconnec_user_and_lv(socket.assigns.room_id, socket.assigns.current_user, self())

    :ok
  end
end
