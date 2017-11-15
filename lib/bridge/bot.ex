defmodule Bridge.Bot do
	use Slack

	def handle_connect(slack, state) do
		
		reverse =
			state.channels
			|> Enum.flat_map(fn {channel, groups} ->
				Enum.map(groups, fn group -> {group, channel} end)
			end)
			|> Enum.group_by(fn {group, _} -> group end, fn {_, channel} -> channel end)
			|> Enum.into(%{})
			|> IO.inspect

		reverse
		|> Map.keys
		|> Enum.map(&group_name/1)
		|> Enum.map(&Radar.join/1)
		

		{:ok, Map.put(state, :reverse, reverse)}
	end

	def handle_event(message = %{type: "message", user: sender, channel: channel}, slack, state) when binary_part(channel, 0, 1) === "C" do
		user = Map.get(slack.users, sender)
		message = Map.put(message, :sender, %{
			team: slack.team.name,
			name: user.name,
			image: user.profile.image_192,
		})

		channel =
			slack.channels
			|> Map.get(message.channel)
			|> Map.get(:name)
		
		state.channels
		|> Map.get("#" <> channel, [])
		|> Enum.each(&broadcast(&1, message))

		{:ok, state}
	end

	def handle_event(_, _, state), do: {:ok, state}

	def handle_info({:message, group, message = %{sender: %{team: team}}}, slack = %{team:  %{name: me}}, state) when team !== me do
		state.reverse
		|> Map.get(group, [])
		|> Enum.map(fn channel ->
			Slack.Web.Chat.post_message(channel, message.text, %{
				icon_url: message.sender.image,
				username: "#{message.sender.name}, #{message.sender.team}",
				token: state.token,
			})
		end)
		{:ok, state}
	end

	def handle_info(_, _, state), do: {:ok, state}

	defp broadcast(group, message) do
		group
		|> group_name
		|> Radar.broadcast({:message, group, message})
	end

	defp group_name(name) do
		{__MODULE__, name}
	end

end