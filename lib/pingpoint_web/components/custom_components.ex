defmodule PingpointWeb.CustomComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import PingpointWeb.CoreComponents, only: [icon: 1]

  attr :name, :string, required: true
  attr :room_id, :integer, required: true
  attr :rest, :global, include: ~w(disabled form name value)

  def room_button(assigns) do
    ~H"""
    <div class="border-t-2 border-t-base-200 flex grow bg-neutral hover:bg-base-100 transition duration-100 ease-in h-12">
      <button
        class={[
          "font-semibold px-4 py-2 text-sm",
          "flex grow gap-4 items-center justify-start"
        ]}
        {@rest}
      >
        <.icon name="hero-server" class="shrink-0" />
        <span class="line-clamp-1"><%= @name %></span>
      </button>
      <button
        type="button"
        class="px-2 group"
        data-confirm={"Are you sure you want to delete room: #{@name}?"}
        phx-click="remove_room"
        phx-value-room={@room_id}
      >
        <.icon
          name="hero-trash"
          class={[
            "w-5 h-5 opacity-30",
            "transition duration-100 ease-in",
            "group-hover:bg-secondary group-hover:opacity-100"
          ]}
        />
      </button>
    </div>
    """
  end
end
