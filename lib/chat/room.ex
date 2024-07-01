defmodule Chat.GenRoom do
  use GenServer

  alias Chat.Message

  def start(id) do
    case GenServer.start_link(__MODULE__, %{room_id: id}, name: {:global, id}) do
      {:error, {:already_started, pid}} ->
        {:already_started, pid}

      {:ok, pid} ->  {:ok, pid}
    end
  end

  def get_room_info(room_id), do:
    GenServer.call({:global, room_id}, :get_room_info)

  def new_message(room_id, msg), do:
    GenServer.cast({:global, room_id}, {:new_message, msg})

  def subscribe(room_id, user, lv_pid), do:
    GenServer.cast({:global, room_id}, {:subscribe, user, lv_pid})

  def disconnec_user_and_lv(room_id, user, lv_pid), do:
    GenServer.cast({:global, room_id}, {:disconnect_user, user, lv_pid})

  def notify_new_chat(room_id, from_user, to_user), do:
    GenServer.cast({:global, room_id}, {:notify_new_chat, from_user, to_user})

  # Callbacks

  @impl true
  def init(state) do
    {:ok,
      %{
        room_id: state.room_id,
        messages: [],
        subscriptions: %{}
      },
      :infinity
    }
  end

  @impl true
  def handle_call(:get_room_info, _, state) do
    info =
      %{
        messages: state.messages,
        name: state.room_id,
        connected_users: Map.keys(state.subscriptions)
      }

    {:reply, info, state}
  end

  @impl true
  def handle_cast({:new_message, msg}, state) do
    new_messages = [msg | state.messages]

    state.subscriptions
    |> Map.values()
    |> List.flatten()
    |> Enum.each(&send(&1, {:update_messages, new_messages}))

    {:noreply, %{state | messages: new_messages}}
  end

  def handle_cast({:subscribe, user, new_pid}, state) do
    lv_pids = Map.get(state.subscriptions, user, [])

    new_pids_list =
      if Enum.member?(lv_pids, new_pid) do
        lv_pids
      else
        [new_pid | lv_pids]
      end

    subscriptions = Map.put(state.subscriptions, user, new_pids_list)

    subscriptions
    |> Map.values()
    |> List.flatten()
    |> Enum.each(&send(&1, {:update_connected_users, Map.keys(subscriptions)}))

    {:noreply, %{state | subscriptions: subscriptions}}
  end

  def handle_cast({:disconnect_user, user, lv_pid}, state) do
    new_subscriptions =
      state.subscriptions
      |> Map.get(user, [])
      |> Enum.reject(& &1 == lv_pid)
      |> case do
        [] ->
          Map.delete(state.subscriptions, user)
        list ->
         Map.put(state.subscriptions, user, list)
      end

    new_messages = [Message.new(:left, user, DateTime.now!("Etc/UTC")) | state.messages]

    new_subscriptions
    |> Map.values()
    |> List.flatten()
    |> Enum.each(fn pid ->
      send(pid, {:update_messages, new_messages})
      send(pid, {:update_connected_users, Map.keys(new_subscriptions)})
    end)

    {:noreply, %{state | subscriptions: new_subscriptions, messages: new_messages}}
  end

  def handle_cast({:notify_new_chat, from_user, to_user}, state) do
    state.subscriptions
    |> Map.get(to_user, [])
    |> Enum.each(& send(&1, {:new_private_chat, from_user}))

    {:noreply, state}
  end
end
