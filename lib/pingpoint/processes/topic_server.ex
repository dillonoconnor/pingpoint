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

  def remove_topic(name, topic_id) do
    GenServer.cast(String.to_atom(name), {:remove_topic, topic_id})
  end

  @impl true
  def init(initial_topics) do
    {:ok, initial_topics}
  end

  @impl true
  def handle_cast({:add_topic, topic}, topics) do
    state = [ topic | topics]
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove_topic, topic_id}, topics) do
    trimmed_dom_id = String.replace(topic_id, "topics-", "")
    {:noreply, Enum.reject(topics, fn topic -> topic.id == trimmed_dom_id end)}
  end

  @impl true
  def handle_call(:get_topics, _from, topics) do
    {:reply, topics, topics}
  end
end
