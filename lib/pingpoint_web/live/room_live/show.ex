defmodule PingpointWeb.RoomLive.Show do
  use PingpointWeb, :live_view

  alias Phoenix.PubSub
  alias Pingpoint.Spaces
  alias Pingpoint.TopicServer

  @pubsub_name Pingpoint.PubSub
  @topic_form_default to_form %{"subject" => ""}
  @user_form_default to_form %{"username" => nil}

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
          topic_form: @topic_form_default,
          user_form: @user_form_default,
          username: session["username"],
          trigger_submit: false
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
  def handle_event("save_topic", topic, socket) do
    PubSub.broadcast(@pubsub_name, socket.assigns.room_id, {:topic_created, topic})
    {:noreply, assign(socket, :topic_form, @topic_form_default)}
  end

  @impl true
  def handle_event("remove_topic", %{"topic-id" => topic_id} = params, socket) do
    IO.inspect(topic_id, label: "a")
    PubSub.broadcast(@pubsub_name, socket.assigns.room_id, {:topic_deleted, topic_id})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:topic_created, topic}, socket) do
    topic = normalize_topic(topic)
    TopicServer.add_topic("topic_server_1", topic)
    {:noreply, stream_insert(socket, :topics, topic)}
  end

  @impl true
  def handle_info({:topic_deleted, topic_id}, socket) do
    TopicServer.remove_topic("topic_server_1", topic_id)
    {:noreply, stream_delete_by_dom_id(socket, :topics, topic_id)}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"

  defp start_topic_server(id) do
    DynamicSupervisor.start_child(Pingpoint.DynamicSupervisor, {TopicServer, [[], name: "topic_server_#{id}"]})
  end

  defp normalize_topic(params) do
    Enum.into(params, %{}, fn {k,v} -> {String.to_atom(k), v} end)
    |> Map.put(:id, Ecto.UUID.generate())
    # |> then(fn topic -> Map.put(topic, :id, Map.get(topic, :topic_id)) end)
    # |> Map.delete(:topic_id)
  end
end
