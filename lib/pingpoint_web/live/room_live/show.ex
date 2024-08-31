defmodule PingpointWeb.RoomLive.Show do
  use PingpointWeb, :live_view

  alias Phoenix.PubSub
  alias Pingpoint.Spaces
  alias Pingpoint.TopicServer

  @pubsub_name Pingpoint.PubSub
  @point_form_default to_form(%{})
  @topic_form_default to_form(%{"subject" => ""})
  @user_form_default to_form(%{"username" => nil})

  @impl true
  def mount(%{"id" => id}, session, socket) do
    room_id = "topic_server_#{id}"

    if connected?(socket), do: PubSub.subscribe(@pubsub_name, room_id)

    socket =
      case start_topic_server(id) do
        {:error, {:already_started, _pid}} ->
          socket |> stream(:topics, TopicServer.get_topics("topic_server_#{id}"))

        _ ->
          socket |> stream(:topics, [])
      end

    socket =
      socket
      |> assign(
        room_id: room_id,
        point_form: @point_form_default,
        topic_form: @topic_form_default,
        user_form: @user_form_default,
        username: session["username"]
      )

    {:ok, socket}
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
    topic =
      TopicServer.update_topic(socket.assigns.room_id, {topic_id, socket.assigns.username, point})

    PubSub.broadcast(@pubsub_name, socket.assigns.room_id, {:topic_updated, topic})
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_topic", %{"subject" => subject}, socket) do
    IO.inspect(subject)
    {:noreply, assign(socket, :topic_form, to_form(%{"subject" => subject}))}
  end

  @impl true
  def handle_event("save_topic", topic, socket) do
    room_id = socket.assigns.room_id
    topic = normalize_topic(topic, room_id)
    TopicServer.add_topic(room_id, topic)
    PubSub.broadcast(@pubsub_name, room_id, {:topic_created, topic})
    {:noreply, assign(socket, :topic_form, @topic_form_default)}
  end

  @impl true
  def handle_event("remove_topic", %{"topic-id" => topic_id}, socket) do
    TopicServer.remove_topic(socket.assigns.room_id, topic_id)
    PubSub.broadcast(@pubsub_name, socket.assigns.room_id, {:topic_deleted, topic_id})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:topic_created, topic}, socket) do
    prev_topic = TopicServer.get_topic(socket.assigns.room_id, topic.row_number - 1)
    socket = socket
    |> (fn sock -> if prev_topic, do: stream_insert(sock, :topics, prev_topic, at: 1), else: sock end).()
    |> stream_insert(:topics, topic, at: 0)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:topic_updated, topic}, socket) do
    socket = stream_insert(socket, :topics, topic, at: 0)

    {:noreply, socket}
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
      {TopicServer, [[], name: "topic_server_#{id}"]}
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
        average: nil,
      })
  end
end
