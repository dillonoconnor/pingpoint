defmodule PingpointWeb.RetroLive.Show do
  use PingpointWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        start_doing_form: to_form(%{start_doing: ""}),
        stop_doing_form: to_form(%{stop_doing: ""}),
        continue_doing_form: to_form(%{continue_doing: ""})
      )

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
      <div class="p-4 bg-base-200 rounded-lg">
        <.form for={@start_doing_form}>
          <label class="input input-bordered flex items-center gap-2">
            <.icon name="hero-hand-thumb-up" />
            <input type="text" class="grow" />
          </label>
        </.form>
      </div>
      <div class="p-4 bg-base-200 rounded-lg">
        <.form for={@stop_doing_form}>
          <label class="input input-bordered flex items-center gap-2">
            <.icon name="hero-hand-thumb-down" />
            <input type="text" class="grow" />
          </label>
        </.form>
      </div>
      <div class="p-4 bg-base-200 rounded-lg">
        <.form for={@continue_doing_form}>
          <label class="input input-bordered flex items-center gap-2">
            <.icon name="hero-heart" />
            <input type="text" class="grow" />
          </label>
        </.form>
      </div>
    </div>
    """
  end
end
