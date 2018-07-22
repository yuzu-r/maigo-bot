module Bot::DiscordCommands
  module Exgyms
    extend Discordrb::Commands::CommandContainer
    command(:exgyms, description: 'list gyms that are eligible to have ex raids') do |_event|
			ex_gyms = ex_gym_lookup
			if !ex_gyms || ex_gyms.count == 0
				_event.bot.send_message(_event.channel.id, 'No ex raid gyms found.')
				return
			else
				embed = Discordrb::Webhooks::Embed.new
				embed.title = "__**Area Gyms Eligible for EX Raids:**__"
				embed.color = 15236612
				description = ""
				ex_gyms.each do |gym|
					if gym['gmap']
						gym_info = '[' + gym['name'] + ']' + '(' + gym['gmap'] + ')'
					else
						gym_info = gym['name']
					end
					description += "\n#{gym_info}"
				end
				if description.length > 2048
					description = description.slice(0,2048)
				end
				embed.description = description
				foot = Discordrb::Webhooks::EmbedFooter.new(text:"Click the gym name for google map.")
				embed.footer = foot
				_event.bot.send_message(_event.channel.id, '',false, embed)
				if Bot::LOGGING == 'true'
					response = log(_event.server.id, _event.user.id, 'exgyms', nil, true)
					if !response || response.n != 1
						puts "could not log exgyms command to database"
					end
				end
			end
			return
    end
  end
end
