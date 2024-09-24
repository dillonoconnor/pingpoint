defmodule PingpointWeb.NewSessionModal do
  use PingpointWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :user_form, to_form(%{"username" => nil}))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id="set-user-modal" allow_cancel={false} show>
        <.simple_form
          action="/set_user"
          autocomplete="off"
          class="flex flex-col justify-between items-center gap-8"
          for={@user_form}
          id="user-form"
        >
          <h4 class="w-full text-left">Avatar</h4>
          <div class="w-3/4 flex self-start justify-between">
            <% image_suffixes = ~w(f1 f2 m1 m2) %>
            <div :for={suffix <- image_suffixes} class="avatar outline-none">
              <input
                id={"avatar-input-#{suffix}"}
                class="absolute peer opacity-0"
                name="avatar"
                type="radio"
                value={suffix}
              />
              <div class="w-24 hover:scale-110 outline outline-neutral-content hover:bg-info rounded transition ease-in-out peer-checked:bg-info peer-checked:scale-110">
                <label for={"avatar-input-#{suffix}"} class="cursor-pointer">
                  <img src={"/images/avatartion#{suffix}.png"} alt={suffix} />
                </label>
              </div>
            </div>
          </div>
          <:inputs>
            <div class="w-full">
              <.input id="user-input" field={@user_form[:username]} label="Name" />
            </div>
            <.button class="bg-base-200">Submit</.button>
          </:inputs>
        </.simple_form>
      </.modal>
    </div>
    """
  end
end
