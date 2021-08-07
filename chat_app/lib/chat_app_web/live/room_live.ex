defmodule ChatAppWeb.RoomLive do
  use ChatAppWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug(2)
    if connected?(socket) do
      ChatAppWeb.Endpoint.subscribe(topic)
      ChatAppWeb.Presence.track(self(), topic, username,  %{})
    end
    Logger.info(room_id)
    {:ok, assign(socket, room_id: room_id, user_list: [], username: username,topic: topic, message: "", messages: [], temporary_assigns: [messages: []]) }
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    Logger.info(message: message)
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username}
    ChatAppWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
    Logger.info(changed_message: message)
    {:noreply, assign(socket, message: message)}
  end


  @impl true
  def handle_info(%{event: "new-message", "payload": message}, socket) do
    Logger.info(message: message)
    {:noreply, assign(socket, messages: [message])}
  end

  @imptl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages = joins
      |> Map.keys()
      |> Enum.map(fn  username ->
        %{type: :system, uuid: UUID.uuid4(), content: "#{username} joined"}
      end)

    leave_messages = leaves
      |> Map.keys()
      |> Enum.map(fn  username ->
        %{type: :system, uuid: UUID.uuid4(), content: "#{username} left"}
      end)

    user_list = ChatAppWeb.Presence.list(socket.assigns.topic)
      |> Map.keys()
    Logger.info(userlist: user_list)
    {:noreply, assign(socket, messages: leave_messages ++ join_messages , user_list: user_list)}
  end

  def display_message(%{type: :system, uuid: uuid, content: content}) do
    ~E"""
    <p id="<%= uuid %>"><em><%= content %></em></p>
    <p>bruh</p>
    """
  end
  def display_message(%{uuid: uuid, content: content, username: username}) do
    ~E"""
    <p id="<%= uuid %>"><strong><%= username %></strong>: <%= content %></p>
    """
  end
end
