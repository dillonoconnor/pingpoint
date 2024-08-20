defmodule PingpointWeb.RoomLive.Show do
  use PingpointWeb, :live_view

  alias Pingpoint.Spaces
  alias Pingpoint.TopicServer

  @user_form_default to_form %{"username" => nil} 

  @impl true
  def mount(%{"id" => id}, session, socket) do
    socket =
      case start_topic_server(id) do
        {:error, {:already_started, _pid}} ->
          socket
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
    topic = Map.new(topic, fn {k,v} -> {String.to_existing_atom(k), v} end)
    TopicServer.add_topic("topic_server_1", topic)

    {:noreply,
     socket
     |> assign(:topic_form, to_form(%{"subject" => "", "reset_key" => :erlang.system_time(:millisecond) |> to_string()}))
     |> stream_insert(:topics, topic)}
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
