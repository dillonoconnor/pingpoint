defmodule PingpointWeb.CustomComponents do
  use Phoenix.Component

  # alias Phoenix.LiveView.JS
  import PingpointWeb.CoreComponents, only: [icon: 1]

  attr :active, :boolean, required: true
  attr :name, :string, required: true
  attr :room_id, :integer, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  def room_button(assigns) do
    ~H"""
    <div class={[
      "border-t-2 border-t-base-200",
      "flex grow h-12",
      unless(@active, do: "hover:bg-base-300 transition duration-100 ease-in"),
      if(@active, do: "bg-base-300", else: "bg-neutral"),
      @class
    ]}>
      <.link
        class={[
          "font-semibold px-4 py-2 text-sm",
          "flex grow gap-4 items-center justify-start"
        ]}
        {@rest}
        navigate={"/rooms/#{@room_id}"}
      >
        <.icon name="hero-server" class="shrink-0" />
        <span class="line-clamp-1"><%= @name %></span>
      </.link>
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
