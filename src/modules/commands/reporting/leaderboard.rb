module Bot::ReportingCommands
  module Alltimeleaderboard
    extend Discordrb::Commands::CommandContainer
    command(:alltime, description: 'raid/egg reporter all-time leaderboard') do |_event|
			response = get_reporters(_event.server.id.to_s)
			rank = 1
			reporter_text = "Thank you to *all* reporters!"
			reporter_text += "\n**+=+=+=+=+=+=+=+=+=+=+**\n"
			response.each do |reporter|
				reporter_nickname = get_user_nickname(_event.server, reporter['_id'])
				if rank == 1
					reporter_text += "\n:first_place: #{reporter_nickname} (#{reporter['total']})"
				else
					reporter_text += "\n    #{reporter_nickname} (#{reporter['total']})"
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
    leaderboard_text = <<~LEADERBOARD_HELP
    	**Leaderboard Command**
    	`#{Bot::PREFIX}alltime`
    	This experimental command will display information about who has reported the most raids/eggs.
    LEADERBOARD_HELP
    Bot::CommandCategories['reporting'].push :alltime => leaderboard_text        
  end
end
