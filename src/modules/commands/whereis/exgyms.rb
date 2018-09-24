module Bot::WhereisCommands
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
					description = "*Note:* Niantic recently changed 'ex raid location' designations."
					description += "\nUntil new ex raid invites go out, the following are suggestions, not confirmed locations."
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
					fallback_msg = "Could not log exgyms command to database!"
					log_command(_event, 'exgyms', true, fallback_msg)				
				end
				return
	    end
	  exgyms_text = "Type `#{Bot::PREFIX}exgyms` to see a listing of El Cerrito/Albany gyms known to hold ex raids."
	  exgyms_text += "\nThere are recent changes to how gyms are marked as 'ex raid eligible'. Until we see ex raid invitations being sent, "
	  exgyms_text += "the displayed gyms should not be interpreted as a definitive list."
		Bot::CommandCategories['lookup'].push :exgyms => exgyms_text
  end
end
