defmodule Pingpoint.TopicServer do
  use GenServer

  def start_link([initial_topics, name: name]) do
    GenServer.start_link(__MODULE__, initial_topics, name: String.to_atom(name))
  end

  def get_topic(name, row_number) do
    GenServer.call(String.to_atom(name), {:get_topic, row_number})
  end

  def get_topics(name) do
    GenServer.call(String.to_atom(name), :get_topics)
  end

  def add_topic(name, topic) do
    topic_name = String.to_atom(name)

    cond do
      topic_count(name) >= 1 ->
        topics = get_topics(name)
        prev_topic_id = topics |> hd() |> Map.get(:id)
        average = topic_average(prev_topic_id, topics)
        GenServer.cast(topic_name, {:add_topic, topic, average})

      true ->
        GenServer.cast(topic_name, {:add_topic, topic, nil})
    end
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
  def handle_cast({:add_topic, topic, average}, topics) do
    updated_topics =
      [topic | topics]
      |> List.update_at(1, &Map.merge(&1, %{current: false, average: average}))

    {:noreply, updated_topics}
  end

  @impl true
  def handle_cast({:remove_topic, topic_id}, topics) do
    {:noreply, Enum.reject(topics, fn topic -> topic.id == trimmed_dom_id(topic_id) end)}
  end

  @impl true
  def handle_call({:get_topic, row_number}, _from, topics) do
    topic = Enum.find(topics, fn topic -> topic.row_number == row_number end)
    {:reply, topic, topics}
  end

  @impl true
  def handle_call(:get_topics, _from, topics) do
    IO.inspect(topics)
    {:reply, topics, topics}
  end

  @impl true
  def handle_call({:update_topic, {dom_id, username, point, user_count}}, _from, topics) do
    topic_id = trimmed_dom_id(dom_id)

    updated_topic =
      find_topic(topic_id, topics)
      |> then(fn topic ->
        points = Map.put(topic.points, username, point)
        %{topic | points: points}
      end)

    updated_topics =
      Enum.map(topics, fn
        %{id: ^topic_id} -> updated_topic
        topic -> topic
      end)

    topic_completed = topic_complete?(topic_id, updated_topics, user_count)

    updated_topic =
      if topic_completed do
        average = topic_average(topic_id, updated_topics)
        %{updated_topic | average: average}
      else
        updated_topic
      end

    status = if topic_completed, do: :complete, else: :pending
    {:reply, {status, updated_topic}, updated_topics}
  end

  @impl true
  def handle_call(:topic_count, _from, topics) do
    {:reply, length(topics), topics}
  end

  defp find_topic(topic_id, topics) do
    Enum.find(topics, fn topic -> topic.id == topic_id end)
  end

  defp trimmed_dom_id(topic_id) do
    String.replace(topic_id, "topics-", "")
  end

  defp topic_average(topic_id, topics) do
    find_topic(topic_id, topics)
    |> then(fn topic ->
      points =
        topic.points
        |> Map.values()
        |> Enum.map(&String.to_integer/1)

      if Enum.empty?(points), do: 0, else: Enum.sum(points) / length(points)
    end)
  end

  defp topic_complete?(topic_id, topics, user_count) do
    point_count =
      find_topic(topic_id, topics)
      |> then(fn topic ->
        Map.keys(topic.points)
        |> length()
      end)

    point_count == user_count
  end
end
