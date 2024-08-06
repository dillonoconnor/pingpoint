defmodule Pingpoint.SpacesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pingpoint.Spaces` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Pingpoint.Spaces.create_room()

    room
  end
end
