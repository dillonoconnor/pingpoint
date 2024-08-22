defmodule PingpointWeb.RoomLive.Show do
  use PingpointWeb, :live_view

  alias Pingpoint.Spaces
  alias Pingpoint.TopicServer
  alias Phoenix.PubSub

  @user_form_default to_form %{"username" => nil}
  @pubsub_name Pingpoint.PubSub

  @impl true
  def mount(%{"id" => id}, session, socket) do
    room_id = "topic_server_#{id}"

    if connected?(socket), do: PubSub.subscribe(@pubsub_name, room_id)

    socket =
      case start_topic_server(id) do
        {:error, {:already_started, _pid}} ->
          socket
          # these change after each refresh which is bad for state management
          |> stream_configure(:topics, dom_id: fn _topic -> "topic-#{Ecto.UUID.generate()}" end)
          |> stream(:topics, TopicServer.get_topics("topic_server_#{id}"))
        _ ->
          socket
          |> stream_configure(:topics, dom_id: fn _topic -> "topic-#{Ecto.UUID.generate()}" end)
          |> stream(:topics, [])
      end

    socket =
      socket
      |> assign(
          room_id: room_id,
          topic_form: topic_form_default(),
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
    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_topic", %{"topic-id" => topic_id}, socket) do
    PubSub.broadcast(@pubsub_name, socket.assigns.room_id, {:topic_deleted, topic_id})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:topic_created, topic}, socket) do
    socket = socket
    |> assign(:topic_form, to_form(%{"subject" => "", "reset_key" => :erlang.system_time(:millisecond) |> to_string()}))
    |> stream_insert(:topics, topic)

    topic = Map.put(topic, :topic_id, socket.assigns.streams.topics.inserts |> hd() |> elem(0))
    TopicServer.add_topic("topic_server_1", topic)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:topic_deleted, topic_id} = message, socket) do
    IO.inspect(message)
    TopicServer.remove_topic("topic_server_1", topic_id)
    {:noreply, stream_delete_by_dom_id(socket, :topics, topic_id)}
  end

  defp topic_form_default do
    to_form %{"subject" => "", "reset_key" => :erlang.system_time(:millisecond) |> to_string()}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"

  defp start_topic_server(id) do
    DynamicSupervisor.start_child(Pingpoint.DynamicSupervisor, {TopicServer, [[], name: "topic_server_#{id}"]})
  end
end
