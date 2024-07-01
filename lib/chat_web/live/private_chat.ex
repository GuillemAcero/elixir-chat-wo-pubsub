defmodule ChatWeb.ChatLive.PrivateChat do
  use ChatWeb, :live_view

  alias Chat.{GenRoom, Message}

  @impl true
  def mount(%{"chat_id" => chat_id},  _, socket) do
    user_keys = Chat.split_chat_id(chat_id)

    if socket.assigns.current_user in user_keys and length(user_keys) == 2 and not is_nil(GenServer.whereis({:global, {:chat, chat_id}})) do
      if connected?(socket) do
        msg = Message.new(:join, socket.assigns.current_user, DateTime.now!("Etc/UTC"))
        GenRoom.new_message({:chat, chat_id}, msg)
        GenRoom.subscribe({:chat, chat_id}, socket.assigns.current_user, self())
      end

      room = GenRoom.get_room_info({:chat, chat_id})

      {:ok,
        socket
        |> assign(talking_to: Enum.find(user_keys, & &1 != socket.assigns.current_user))
        |> assign(messages: room.messages)
        |> assign(chat_id: chat_id)
      }
    else
      {:ok,
        socket
        |> put_flash(:error, "Page does not exist")
        |> redirect(to: ~p"/lobby")
      }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center text-4xl">
        <%= "Chat with #{@talking_to}" %>
      </div>

      <div class="col-span-8 border rounded-md h-96 p-3 overflow-y-auto">
        <%= for message <- Enum.reverse(@messages) do %>
          <.message message={message} current_user={@current_user} />
        <% end %>
      </div>

      <form phx-submit="add-message" class="mt-5">
        <div class="w-full grid grid-cols-10 gap-2">
          <input name="message" id="message" class="col-span-8 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6" type="text" required />
          <.button class="w-full col-span-2">Send ></.button>
        </div>
      </form>
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
        <%= @message.message %>
      </div>
    </div>
    """
  end

  def message(assigns) do
    ~H"""
    <div class="flex justify-start my-1">
      <div class="rounded-lg bg-gray-100 text-gray-800 px-3 py-1">
        <%= @message.message %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("add-message", %{"message" => msg}, socket) do
    new_message =
      Message.new(:msg, socket.assigns.current_user, DateTime.now!("Etc/UTC"), msg)

      GenRoom.new_message({:chat, socket.assigns.chat_id}, new_message)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:update_messages, messages}, socket) do
    {:noreply, assign(socket, :messages, messages)}
  end

  def handle_info({:update_connected_users, users}, socket) do
    {:noreply, assign(socket, :connected_users, users)}
  end

  @impl true
  def terminate(_reason, socket) do
    GenRoom.disconnec_user_and_lv({:chat, socket.assigns.chat_id}, socket.assigns.current_user, self())

    :ok
  end
end
