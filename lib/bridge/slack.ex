defmodule Bridge.Slack do
	def tags(input) do
		Regex.scan(~r/\<@([^\>]+)\>/, input) ++ Regex.scan(~r/(?<!\<)@([^\W]+)/, input)
	end

	def find_user(slack, name) do
		slack.users
		|> Enum.find(&(&1.name |> IO.inspect === name))
	end
end