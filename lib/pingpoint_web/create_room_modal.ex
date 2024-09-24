defmodule PingpointWeb.CreateRoomModal do
  use PingpointWeb, :live_component

  alias Pingpoint.Spaces
  alias Pingpoint.Spaces.Room

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :create_room_form, Spaces.change_room(%Room{}) |> to_form())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id="create-room-modal">
        <.simple_form
          autocomplete="off"
          class="flex flex-col justify-between items-center gap-8"
          for={@create_room_form}
          phx-change="validate_room"
          phx-submit="save_room"
        >
          <:inputs>
            <div class="w-full">
              <.input field={@create_room_form[:name]} label="Name" phx-debounce="500" />
            </div>
            <.button class="bg-base-200">Submit</.button>
          </:inputs>
        </.simple_form>
      </.modal>
    </div>
    """
  end
end
