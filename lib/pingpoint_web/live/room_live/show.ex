defmodule PingpointWeb.RoomLive.Show do
  use PingpointWeb, :live_view

  alias Pingpoint.Spaces

  @topic_form_default to_form %{"subject" => ""}
  @user_form_default to_form %{"username" => ""} 

  @impl true
  def mount(_params, _session, socket) do
    socket = socket
    |> assign(
        topic_form: @topic_form_default,
        user_form: @user_form_default,
        trigger_submit: false
      )
    |> stream(:topics, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Spaces.get_room!(id))}
  end

  def handle_event("save_topic", topic, socket) do
    topic = Map.new(topic, fn {k,v} -> {String.to_existing_atom(k), v} end)

    {:noreply,
     socket
     |> assign(:form, @topic_form_default)
     |> stream_insert(:topics, topic)}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
