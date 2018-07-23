module Bot::DiscordCommands
  module Leaderboard
    extend Discordrb::Commands::CommandContainer
    command(:leaderboard, description: 'raid/egg reporter leaderboard') do |_event|
			response = get_reporters(_event.server.id.to_s)
			rank = 1
			reporter_text = "Thank you to *all* reporters!"
			reporter_text += "\n**+=+=+=+=+=+=+=+=+=+=+**\n"
			response.each do |reporter|
				if rank == 1
					reporter_text += "\n:first_place: #{reporter['_id']} (#{reporter['total']})"
				else
					reporter_text += "\n    #{reporter['_id']} (#{reporter['total']})"
				end
				rank += 1
			end
			reporter_text += "\n\n**+=+=+=+=+=+=+=+=+=+=+**"
			embed = Discordrb::Webhooks::Embed.new
			embed.title = "__**Raid Reporter Leaderboard**__"
			embed.color = 15236612
			embed.description = reporter_text
			embed.timestamp = Time.now
			_event.bot.send_message(_event.channel.id,'',false, embed)
			return
    end
  end
end
