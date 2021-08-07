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
    {:ok, assign(socket, room_id: room_id, username: username,topic: topic, message: "", messages: [%{uuid: UUID.uuid4(), content: "#{username} joined the chat", username: "system"}], temporary_assigns: [messages: []]) }
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
    Logger.info(joins: joins, leaves: leaves)
    join_message = joins
      |> Map.keys()
      |> Enum.map(fn  username ->
        %{uuid: UUID.uuid4(), content: "#{username} joined", type: :system}
      end)

    leave_message = leaves
      |> Map.keys()
      |> Enum.map(fn  username ->
        %{uuid: UUID.uuid4(), content: "#{username} left", type: :system}
      end)
    {:noreply, socket}
  end
end
