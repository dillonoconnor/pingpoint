defmodule PingpointWeb.RetroLive.Show do
  use PingpointWeb, :live_view

  alias Pingpoint.RetroAgent

  defmodule Comment do
    defstruct id: Ecto.UUID.generate(), content: nil, author: nil
  end

  @impl true
  def mount(_params, session, socket) do
    {:ok, _pid} = RetroAgent.start_link(:ra)

    socket =
      socket
      |> assign(
        start_doing_form: to_form(%{"start_doing" => ""}),
        stop_doing_form: to_form(%{"stop_doing" => ""}),
        continue_doing_form: to_form(%{"continue_doing" => ""}),
        username: session["username"]
      )
      |> stream(:start_doing, RetroAgent.get(:ra, "start_doing"))
      |> stream(:stop_doing, RetroAgent.get(:ra, "stop_doing"))
      |> stream(:continue_doing, RetroAgent.get(:ra, "continue_doing"))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grow grid grid-cols-3 grid-rows-[1fr_8fr] gap-4">
      <div class="bg-base-300 p-4 rounded-lg flex items-center justify-center text-xl font-semibold">
        Start Doing
      </div>
      <div class="bg-base-300 p-4 rounded-lg flex items-center justify-center text-xl font-semibold">
        Stop Doing
      </div>
      <div class="bg-base-300 p-4 rounded-lg flex items-center justify-center text-xl font-semibold">
        Continue Doing
      </div>
      <div
        :for={category <- [:start_doing, :stop_doing, :continue_doing]}
        class="flex flex-col h-full p-4 bg-base-200 rounded-lg"
      >
        <% stringified_category = Atom.to_string(category) %>
        <div phx-update="stream" id={stringified_category <> "-comments"}>
          <div :for={{_id, comment} <- @streams[category]} class="mt-4 chat chat-start">
            <div class="chat-header">
              <%= comment.author %>
            </div>
            <div class="chat-bubble">
              <%= comment.content %>
            </div>
          </div>
        </div>
        <.form for={assigns[category]} class="mt-auto w-full" phx-submit="add_content">
          <label for={stringified_category} class="input input-bordered flex items-center gap-2">
            <.icon name={category_icon(category)} />
            <input type="hidden" name="author" value={@username} />
            <input type="hidden" name="category" value={stringified_category} />
            <input id={stringified_category} type="text" class="grow" name="content" />
          </label>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("add_content", params, socket) do
    %{"author" => author, "category" => category, "content" => content} = params
    comment = %Comment{author: author, content: content}
    RetroAgent.put(:ra, category, comment)

    {:noreply, stream_insert(socket, String.to_existing_atom(category), comment)}
  end

  defp category_icon(category) do
    case category do
      :start_doing -> "hero-light-bulb"
      :stop_doing -> "hero-hand-thumb-down"
      :continue_doing -> "hero-heart"
    end
  end
end
