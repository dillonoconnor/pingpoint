defmodule Pingpoint.RetroAgent do
  use Agent

  def start_link(name) do
    comments = %{"start_doing" => [], "stop_doing" => [], "continue_doing" => []}

    case Agent.start_link(fn -> comments end, name: name) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  def get(name, category) do
    Agent.get(name, &Map.get(&1, category))
  end

  def put(name, category, comment) do
    Agent.update(name, fn comments ->
      %{comments | category => [comment | Map.get(comments, category)]}
    end)
  end
end
