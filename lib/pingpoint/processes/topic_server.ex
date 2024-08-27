defmodule Pingpoint.TopicServer do
  use GenServer

  def start_link([initial_topics, name: name]) do
    GenServer.start_link(__MODULE__, initial_topics, name: String.to_atom(name))
  end

  def get_topics(name) do
    GenServer.call(String.to_atom(name), :get_topics)
  end

  def add_topic(name, topic) do
    GenServer.cast(String.to_atom(name), {:add_topic, topic})
  end

  def update_topic(name, payload) do
    GenServer.call(String.to_atom(name), {:update_topic, payload})
  end

  def remove_topic(name, topic_id) do
    GenServer.cast(String.to_atom(name), {:remove_topic, topic_id})
  end

  def topic_count(name) do
    GenServer.call(String.to_atom(name), :topic_count)
  end

  @impl true
  def init(initial_topics) do
    {:ok, initial_topics}
  end

  @impl true
  def handle_cast({:add_topic, topic}, topics) do
    state = [topic | topics]
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove_topic, topic_id}, topics) do
    {:noreply, Enum.reject(topics, fn topic -> topic.id == trimmed_dom_id(topic_id) end)}
  end

  @impl true
  def handle_call(:get_topics, _from, topics) do
    IO.inspect(topics)
    {:reply, topics, topics}
  end

  @impl true
  def handle_call({:update_topic, {topic_id, username, point}}, _from, topics) do
    dom_id = trimmed_dom_id(topic_id)

    updated_topic =
      Enum.find(topics, fn topic -> topic.id == dom_id end)
      |> then(fn topic ->
        IO.inspect(topic, label: "topic")
        updated_points = Map.put(topic.points, username, point)
        %{topic | points: updated_points}
      end)

    updated_topics =
      Enum.map(topics, fn
        %{id: ^dom_id} -> updated_topic
        topic -> topic
      end)

    {:reply, updated_topic, updated_topics}
  end

  @impl true
  def handle_call(:topic_count, _from, topics) do
    {:reply, Enum.count(topics), topics}
  end

  defp trimmed_dom_id(topic_id) do
    String.replace(topic_id, "topics-", "")
  end
end
