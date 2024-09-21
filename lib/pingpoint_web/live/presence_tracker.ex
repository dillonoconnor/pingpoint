defmodule PingpointWeb.PresenceTracker do
  use PingpointWeb, :live_component

  alias Phoenix.PubSub
  alias PingpointWeb.Presence

  @pubsub_name Pingpoint.PubSub

  def mount(socket) do
    {:ok, socket}
  end

  def update(
        %{
          presence_payload: %{
            avatar_suffix: avatar_suffix,
            topic_server: topic_server,
            username: username
          }
        } = presence_payload,
        socket
      ) do
    if connected?(socket) do
      Presence.track(self(), topic_server, username, %{
        thinking: Presence.get_by_key(topic_server, username)[:thinking] || true,
        avatar: avatar_suffix && "avatartion#{avatar_suffix}"
      })

      PubSub.subscribe(@pubsub_name, topic_server)
    end

    presences =
      Presence.list(topic_server)
      |> uniq_presence_map()

    socket =
      socket
      |> assign(Map.to_list(presence_payload))
      |> assign(:presences, presences)

    {:ok, socket}
  end

  def update(%{leaves: leaves, joins: joins}, socket) do
    socket =
      socket
      |> remove_presences(leaves)
      |> add_presences(joins)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <article class="w-48">
      <ul class="flex flex-col gap-2">
        <li :for={{user, meta} <- @presences}>
          <.user_bar user={user} meta={meta} />
        </li>
      </ul>
    </article>
    """
  end

  def user_bar(assigns) do
    ~H"""
    <div class="flex justify-between items-center bg-neutral py-2 pr-4 rounded-lg border border-info text-center h-12 overflow-hidden">
      <span class="flex items-center gap-2">
        <div class="avatar">
          <div class="h-16 w-16">
            <%= if @meta.avatar do %>
              <img src={"/images/#{@meta.avatar}.png"} />
            <% else %>
              <.icon name="hero-question-mark-circle" />
            <% end %>
          </div>
        </div>
        <span class="line-clamp-1 pr-2"><%= @user %></span>
      </span>
      <.icon
        class="shrink-0"
        name={if @meta.thinking, do: "hero-ellipsis-horizontal", else: "hero-check"}
      />
    </div>
    """
  end

  defp uniq_presence_map(presences) do
    Enum.into(presences, %{}, fn {user, %{metas: [meta | _]}} ->
      {user, meta}
    end)
  end

  defp remove_presences(socket, leaves) do
    presences = Map.drop(socket.assigns.presences, Map.keys(leaves))
    assign(socket, :presences, presences)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, uniq_presence_map(joins))
    assign(socket, :presences, presences)
  end
end
