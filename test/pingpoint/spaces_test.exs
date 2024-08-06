defmodule Pingpoint.SpacesTest do
  use Pingpoint.DataCase

  alias Pingpoint.Spaces

  describe "rooms" do
    alias Pingpoint.Spaces.Room

    import Pingpoint.SpacesFixtures

    @invalid_attrs %{name: nil}

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Spaces.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Spaces.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Room{} = room} = Spaces.create_room(valid_attrs)
      assert room.name == "some name"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Spaces.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Room{} = room} = Spaces.update_room(room, update_attrs)
      assert room.name == "some updated name"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Spaces.update_room(room, @invalid_attrs)
      assert room == Spaces.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Spaces.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Spaces.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Spaces.change_room(room)
    end
  end
end
