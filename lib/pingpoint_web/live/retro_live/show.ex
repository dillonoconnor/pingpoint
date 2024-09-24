defmodule PingpointWeb.RetroLive.Show do
  use PingpointWeb, :live_view

  alias Phoenix.PubSub
  alias Pingpoint.RetroAgent
  alias PingpointWeb.NewSessionModal
  alias PingpointWeb.PresenceTracker

  defmodule Comment do
    defstruct id: nil, content: nil, author: nil
  end

  @pubsub_name Pingpoint.PubSub

  @impl true
  def mount(_params, session, socket) do
    avatar_suffix = session["avatar"]
    username = session["username"]

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        Pingpoint.DynamicSupervisor,
        {RetroAgent, :ra}
      )

    presence_payload = %{
      avatar_suffix: avatar_suffix,
      topic_server: "ra",
      username: username
    }

    socket =
      socket
      |> assign(
        start_doing_form: to_form(%{"start_doing" => ""}),
        stop_doing_form: to_form(%{"stop_doing" => ""}),
        continue_doing_form: to_form(%{"continue_doing" => ""}),
        username: username,
        presence_payload: presence_payload
      )
      |> stream(:start_doing, RetroAgent.get(:ra, "start_doing") |> Enum.reverse())
      |> stream(:stop_doing, RetroAgent.get(:ra, "stop_doing") |> Enum.reverse())
      |> stream(:continue_doing, RetroAgent.get(:ra, "continue_doing") |> Enum.reverse())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component :if={!@username} module={NewSessionModal} id={:new} />
    <section class="grow mt-4 flex justify-between gap-8 max-w-screen-2xl">
      <.live_component module={PresenceTracker} id={:users} presence_payload={@presence_payload} />
      <div class="grow grid grid-cols-3 grid-rows-[1fr_8fr] gap-4">
        <.col_header title="Start Doing" />
        <.col_header title="Stop Doing" />
        <.col_header title="Continue Doing" />
        <div
          :for={category <- [:start_doing, :stop_doing, :continue_doing]}
          class="flex flex-col h-full p-4 bg-base-200 rounded-lg"
        >
          <% stringified_category = Atom.to_string(category) %>
          <div
            phx-update="stream"
            id={stringified_category <> "-comments"}
            class="grow h-0 overflow-y-auto"
          >
            <.chat_bubble :for={{id, comment} <- @streams[category]} id={id} comment={comment} />
          </div>
          <.form
            for={assigns[category]}
            class="mt-4 w-full"
            phx-change="validate_comment"
            phx-submit="add_content"
          >
            <label for={stringified_category} class="input input-bordered flex items-center gap-2">
              <.icon name={category_icon(category)} />
              <input type="hidden" name="author" value={@username} autocomplete="off" />
              <input type="hidden" name="category" value={stringified_category} autocomplete="off" />
              <input
                id={stringified_category}
                type="text"
                class="grow"
                name="content"
                autocomplete="off"
                phx-debounce="500"
              />
            </label>
          </.form>
        </div>
      </div>
    </section>
    """
  end

  def col_header(assigns) do
    ~H"""
    <div class="bg-base-300 p-4 rounded-lg flex items-center justify-center text-xl font-semibold">
      <%= @title %>
    </div>
    """
  end

  def chat_bubble(assigns) do
    ~H"""
    <div id={@id} class="mt-4 chat chat-start">
      <div class="chat-header">
        <%= @comment.author %>
      </div>
      <div class="chat-bubble">
        <%= @comment.content %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event(
        "validate_comment",
        %{"category" => category, "content" => content} = params,
        socket
      ) do
    IO.inspect(params, label: "params")

    {:noreply,
     assign(socket, String.to_atom("#{category}_form"), to_form(%{category => content}))}
  end

  @impl true
  def handle_event("add_content", params, socket) do
    %{"author" => author, "category" => category, "content" => content} = params
    comment = %Comment{id: Ecto.UUID.generate(), author: author, content: content}
    RetroAgent.put(:ra, category, comment)
    PubSub.broadcast(@pubsub_name, "ra", {:comment_created, category, comment})
    {:noreply, socket}
  end

  @impl true
  def handle_info({:comment_created, category, comment}, socket) do
    {:noreply, stream_insert(socket, String.to_existing_atom(category), comment)}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    send_update(PresenceTracker, id: :users, leaves: payload.leaves, joins: payload.joins)

    {:noreply, socket}
  end

  defp category_icon(category) do
    case category do
      :start_doing -> "hero-light-bulb"
      :stop_doing -> "hero-hand-thumb-down"
      :continue_doing -> "hero-heart"
    end
  end
end
