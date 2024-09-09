defmodule PingpointWeb.RoomLive.Show do
  use PingpointWeb, :live_view

  alias Phoenix.PubSub
  alias Pingpoint.Spaces
  alias Pingpoint.TopicServer
  alias PingpointWeb.Presence

  @pubsub_name Pingpoint.PubSub
  @point_form_default to_form(%{})
  @topic_form_default to_form(%{"subject" => ""})

  @impl true
  def mount(%{"id" => id}, %{"username" => username, "avatar" => avatar_suffix}, socket) do
    room_id = "topics:topic_#{id}"
    topic_id = "users:topic_#{id}"

    if connected?(socket) do
      Presence.track(self(), topic_id, username, %{
        thinking: Presence.get_by_key(topic_id, username)[:thinking] || true,
        avatar: "avatartion#{avatar_suffix}"
      })

      PubSub.subscribe(@pubsub_name, topic_id)
      PubSub.subscribe(@pubsub_name, room_id)
    end

    presences =
      Presence.list(topic_id)
      |> uniq_presence_map()

    socket =
      case start_topic_server(id) do
        {:error, {:already_started, _pid}} ->
          socket |> stream(:topics, TopicServer.get_topics(room_id))

        _ ->
          socket |> stream(:topics, [])
      end

    socket =
      socket
      |> assign(
        room_id: room_id,
        topic_id: topic_id,
        point_form: @point_form_default,
        topic_form: @topic_form_default,
        username: username,
        presences: presences,
        status: :complete,
        rooms: Spaces.list_rooms()
      )

    {:ok, socket}
  end

  @impl true
  def mount(_, _, socket) do
    socket = put_flash(socket, :error, "You must have a username to enter a room")
    {:ok, redirect(socket, to: ~p"/rooms")}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Spaces.get_room!(id))}
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
  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    IO.inspect(payload, label: "payload")

    socket =
      socket
      |> remove_presences(payload.leaves)
      |> add_presences(payload.joins)

    {:noreply, socket}
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

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"

  defp start_topic_server(id) do
    DynamicSupervisor.start_child(
      Pingpoint.DynamicSupervisor,
      {TopicServer, [[], name: "topics:topic_#{id}"]}
    )
  end

  defp remove_presences(socket, leaves) do
    presences = Map.drop(socket.assigns.presences, Map.keys(leaves))
    assign(socket, :presences, presences)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, uniq_presence_map(joins))
    assign(socket, :presences, presences)
  end

  defp update_presence(socket, key, value) do
    username = socket.assigns.username
    topic_id = socket.assigns.topic_id

    Presence.get_by_key(topic_id, username).metas
    |> hd()
    |> then(fn meta ->
      Presence.update(self(), topic_id, username, %{meta | key => value})
    end)

    socket
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

  defp uniq_presence_map(presences) do
    Enum.into(presences, %{}, fn {user, %{metas: [meta | _]}} ->
      {user, meta}
    end)
  end
end
