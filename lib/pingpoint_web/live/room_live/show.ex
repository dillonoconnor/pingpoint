defmodule PingpointWeb.RoomLive.Show do
  use PingpointWeb, :live_view

  alias Phoenix.PubSub
  alias Pingpoint.TopicServer
  alias Pingpoint.Spaces
  alias Pingpoint.Spaces.Room
  alias PingpointWeb.CreateRoomModal
  alias PingpointWeb.NewSessionModal
  alias PingpointWeb.Presence
  alias PingpointWeb.PresenceTracker

  @pubsub_name Pingpoint.PubSub
  @point_form_default to_form(%{})
  @topic_form_default to_form(%{"subject" => ""})

  @impl true
  def mount(params, session, socket) do
    id = params["id"] || "1"
    room_id = "topics:topic_#{id}"
    topic_id = "users:topic_#{id}"
    username = session["username"]
    avatar_suffix = session["avatar"]

    if connected?(socket) do
      PubSub.subscribe(@pubsub_name, room_id)
    end

    presence_payload = %{
      avatar_suffix: avatar_suffix,
      topic_server: topic_id,
      username: username
    }

    socket =
      case start_topic_server(id) do
        {:error, {:already_started, _pid}} ->
          socket |> stream(:topics, TopicServer.get_topics(room_id))

        _ ->
          socket |> stream(:topics, [])
      end

    socket = stream(socket, :rooms, Spaces.list_rooms())

    socket =
      socket
      |> assign(
        presence_payload: presence_payload,
        params_room_id: String.to_integer(id),
        room_id: room_id,
        topic_id: topic_id,
        point_form: @point_form_default,
        topic_form: @topic_form_default,
        username: username,
        status: :complete
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, assign(socket, :page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_event("save_point", %{"topic_id" => topic_id, "point" => point}, socket) do
    room_id = socket.assigns.room_id
    topic_server = socket.assigns.topic_id

    user_count = Presence.list(topic_server) |> map_size()

    {status, topic} =
      TopicServer.update_topic(room_id, {topic_id, socket.assigns.username, point, user_count})

    PubSub.broadcast(@pubsub_name, room_id, {:topic_updated, topic})

    if status == :complete,
      do: PubSub.broadcast(@pubsub_name, topic_server, {:set_status, status})

    {:noreply, update_presence(socket, :thinking, false)}
  end

  @impl true
  def handle_event("validate_topic", %{"subject" => subject}, socket) do
    {:noreply, assign(socket, :topic_form, to_form(%{"subject" => subject}))}
  end

  @impl true
  def handle_event("save_topic", topic, socket) do
    room_id = socket.assigns.room_id
    topic_server = socket.assigns.topic_id
    topic = normalize_topic(topic, room_id)

    TopicServer.add_topic(room_id, topic)
    PubSub.broadcast(@pubsub_name, room_id, {:topic_created, topic})
    PubSub.broadcast(@pubsub_name, topic_server, :reset_thinking)
    PubSub.broadcast(@pubsub_name, topic_server, {:set_status, :pending})

    {:noreply, assign(socket, :topic_form, @topic_form_default)}
  end

  @impl true
  def handle_event("remove_topic", %{"topic-id" => topic_id}, socket) do
    TopicServer.remove_topic(socket.assigns.room_id, topic_id)
    PubSub.broadcast(@pubsub_name, socket.assigns.room_id, {:topic_deleted, topic_id})
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_room", %{"room" => room_params}, socket) do
    {:ok, room} = Spaces.create_room(room_params)

    socket =
      socket
      |> stream_insert(:rooms, room)
      |> push_event("hide_element", %{"id" => "create-room-modal"})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_room", %{"room" => room_params}, socket) do
    changeset =
      %Room{}
      |> Spaces.change_room(room_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :create_room_form, to_form(changeset))}
  end

  @impl true
  def handle_event("remove_room", %{"room" => room_id}, socket) do
    room = Spaces.get_room!(room_id)
    {:ok, room} = Spaces.delete_room(room)
    {:noreply, stream_delete(socket, :rooms, room)}
  end

  @impl true
  def handle_info(:reset_thinking, socket) do
    {:noreply, update_presence(socket, :thinking, true)}
  end

  @impl true
  def handle_info({:set_status, status}, socket) do
    {:noreply, assign(socket, status: status)}
  end

  @impl true
  def handle_info({:topic_created, topic}, socket) do
    prev_topic = TopicServer.get_topic(socket.assigns.room_id, topic.row_number - 1)

    socket =
      socket
      |> (fn sock ->
            if prev_topic, do: stream_insert(sock, :topics, prev_topic, at: 1), else: sock
          end).()
      |> stream_insert(:topics, topic, at: 0)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:topic_updated, topic}, socket) do
    {:noreply, stream_insert(socket, :topics, topic, at: 0)}
  end

  @impl true
  def handle_info({:topic_deleted, topic_id}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :topics, topic_id)}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    send_update(PresenceTracker, id: :users, leaves: payload.leaves, joins: payload.joins)

    {:noreply, socket}
  end

  def point_tooltip(point) do
    case point do
      "1" -> "half a day"
      "2" -> "one day"
      "3" -> "a few days"
      "5" -> "a week"
      "8" -> "more than a week"
      _ -> "?"
    end
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"

  defp start_topic_server(id) do
    DynamicSupervisor.start_child(
      Pingpoint.DynamicSupervisor,
      {TopicServer, [[], name: "topics:topic_#{id}"]}
    )
  end

  defp normalize_topic(params, room_id) do
    row_number = TopicServer.topic_count(room_id) + 1

    Enum.into(params, %{}, fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.merge(%{
      id: Ecto.UUID.generate(),
      points: %{},
      row_number: row_number,
      current: true,
      average: nil
    })
  end

  defp update_presence(socket, key, value) do
    username = socket.assigns.username
    topic_server = socket.assigns.topic_id

    Presence.get_by_key(topic_server, username).metas
    |> hd()
    |> then(fn meta ->
      Presence.update(self(), topic_server, username, %{meta | key => value})
    end)

    socket
  end
end
