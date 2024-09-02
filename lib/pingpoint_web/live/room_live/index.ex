defmodule PingpointWeb.RoomLive.Index do
  use PingpointWeb, :live_view

  alias Pingpoint.Spaces
  alias Pingpoint.Spaces.Room

  @user_form_default to_form(%{"username" => nil})

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(user_form: @user_form_default, username: session["username"])
      |> stream(:rooms, Spaces.list_rooms())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room")
    |> assign(:room, Spaces.get_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Rooms")
    |> assign(:room, nil)
  end

  @impl true
  def handle_info({PingpointWeb.RoomLive.FormComponent, {:saved, room}}, socket) do
    {:noreply, stream_insert(socket, :rooms, room)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room = Spaces.get_room!(id)
    {:ok, _} = Spaces.delete_room(room)

    {:noreply, stream_delete(socket, :rooms, room)}
  end
end
