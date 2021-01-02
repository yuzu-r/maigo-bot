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
					embed.color = 15236612
					foot = Discordrb::Webhooks::EmbedFooter.new(text:"Click the gym name for google map.")
					embed.footer = foot			
					description = "The gyms listed here all display an Ex Raid tag when viewed in PoGO."
					description += "\nHowever, not all of them regularly hold ex raids."
					ex_gyms.each do |gym|
						if gym['gmap']
							gym_info = '[' + gym['name'] + ']' + '(' + gym['gmap'] + ')'
						else
							gym_info = gym['name']
						end
						description += "\n#{gym_info}"
					end
					description_array = Discordrb::split_message(description)
					description_array.each_with_index do |d, i|
						embed.title = "__**Area Gyms Eligible for EX Raids (#{i + 1}/#{description_array.size}):**__"
						embed.description = d
						_event.bot.send_message(_event.channel.id, '',false, embed)	
					end
					fallback_msg = "Could not log exgyms command to database!"
					log_command(_event, 'exgyms', true, fallback_msg)
				end
				return	    
			end
		exgyms_text = <<~EXGYMS_HELP
			Type `#{Bot::PREFIX}exgyms` to see a listing of El Cerrito/Albany gyms eligible to hold ex raids.
			(Not all of the eligible gyms regularly hold ex raids.)
		EXGYMS_HELP
	  #exgyms_text = "Type `#{Bot::PREFIX}exgyms` to see a listing of El Cerrito/Albany gyms eligible to hold ex raids."
	  #exgyms_text += "\n(Not all of the eligible gyms regularly hold ex raids.)"
		Bot::CommandCategories['lookup'].push :exgyms => exgyms_text
  end
end
