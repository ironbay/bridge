defmodule Bridge.Bot do
	use Slack

	def handle_connect(slack, state) do
	
		subs =
			state.groups
			|> Enum.reduce(BiMultiMap.new, &BiMultiMap.put(&2, &1))

		subs
		|> BiMultiMap.values
		|> Enum.map(&group_name/1)
		|> Enum.map(&Radar.join/1)
	
		{:ok,
			state
			|> Map.put(:subs, subs)
		}
	end

	def handle_event(message = %{type: "message", user: sender, channel: channel}, slack, state) when binary_part(channel, 0, 1) === "C" do
		user = Map.get(slack.users, sender)
		text =
			message.text
			|> Bridge.Slack.tags
			|> Enum.reduce(message.text, fn [match, user], collect ->
				name = Dynamic.get(slack.users, [user, :name]) || user
				String.replace(collect, match, "<@#{name}>")
			end)
			
		message =
			message
			|> Map.put(:sender, %{
				team: slack.team.name,
				name: user.name,
				image: user.profile.image_192,
			})
			|> Map.put(:text, text)

		channel =
			slack.channels
			|> Map.get(message.channel)
			|> Map.get(:name)
		
		state.subs
		|> BiMultiMap.get(channel)
		|> Enum.each(&broadcast(&1, message))

		{:ok, state}
	end

	def handle_event(_, _, state), do: {:ok, state}

	def handle_info({:message, group, message = %{sender: %{team: team}}}, slack = %{team:  %{name: me}}, state) when team !== me do
		state.subs
		|> BiMultiMap.get_keys(group)
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