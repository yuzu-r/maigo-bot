module Bot::ReportingCommands
  module Egg
    extend Discordrb::Commands::CommandContainer
    command(:egg, description: 'report an egg') do |_event, *egg_info|
    	server_id = _event.server.id
			tier_list = [1,2,3,4,5]
			parsed_egg_data = comma_parse(egg_info)
			if parsed_egg_data.count < 2 || parsed_egg_data.count > 3
				usage_msg = "Usage: #{Bot::PREFIX}egg *gym*, *minutes or time to hatch*, *tier* (separated by commas)"
				_event.respond _event.user.mention + ' ' + usage_msg
				updateDeleteMessageQueue(Bot::DeleteEggMessageQueue[server_id], _event, false)
				return
			else
				tier = parsed_egg_data.count == 2 ? 5 : parsed_egg_data[2]
				gym = parsed_egg_data[0]
				time_string = parsed_egg_data[1]
				# no tags in the boss like <@!342468337999151116> or @here
				if gym.include?('@')
					error_msg = "No tags or mentions are allowed in the raid report."
					_event.respond _event.user.mention + ' ' + error_msg
					updateDeleteMessageQueue(Bot::DeleteEggMessageQueue[server_id], _event, false)
					#_event.message.delete 
					return
				end
			end

			if tier_list.include?(tier.to_i)
		  	hatch_data = get_active_range(time_string)
		  	if !hatch_data
		  		time_error_msg = 'Please enter minutes to hatch or a valid time (e.g. 12:23)'
		  		_event.respond _event.user.mention + ' ' + time_error_msg
		  		updateDeleteMessageQueue(Bot::DeleteEggMessageQueue[server_id], _event, false)
		  		return
		  	else
		  		hatch_time, despawn_time = hatch_data
		  	end
		  	egg_channel = get_raids_channel(_event.server)
				username = _event.user.display_name

		  	# match color to tier
		  	case tier.to_i
		  	when 1..2
		  		color = 16724889
		  	when 3..4
		  		color = 13421568
		  	else
		  		color = 8028868
		  	end

				gym_data = lookup(gym)
				if gym_data['gmap']
					gym_info = '[' + gym + ']' + '(' + gym_data['gmap'] + ')'
				else
					gym_info = gym
				end

		  	response = register_egg(gym, hatch_time, despawn_time, tier.to_i, username, _event.server.id)
				if !response || response.n != 1
					puts "could not log egg to database"
					is_success = false
				else
					is_success = true
				end

=begin
				# this is too spammy
		  	embed = Discordrb::Webhooks::Embed.new
		  	embed.title = "**#{tier}* hatches #{hatch_time.strftime("%-I:%M")} (despawns #{despawn_time.strftime("%-I:%M")})**"
		  	embed.color = color
		  	embed.description = "Gym: #{gym_info} (reported by #{username})"
		  	_event.bot.send_message(egg_channel.id, '',false, embed)
=end
				sort_and_pin(_event)
		  	_event.message.react("✅")
		  	updateDeleteMessageQueue(Bot::DeleteEggMessageQueue[server_id], _event)
			else
				_event.respond _event.user.mention + ' Please check the egg tier (1-5 allowed)'
				updateDeleteMessageQueue(Bot::DeleteEggMessageQueue[server_id], _event, false)
			end

			return
			fallback_msg = "Could not log egg command to database!"
			log_command(_event, 'egg', is_success, fallback_msg)
    end
  	egg_text = "\n**Egg Reporting**"
  	egg_text += "\n`#{Bot::PREFIX}egg [gym], [minutes to hatch OR hatch time], [optional tier]`"
  	egg_text += "\n if no tier (1-5) is included, the egg is assumed to be tier 5."
  	egg_text += "\n**Examples:**"
  	egg_text += "\nTo report a 5:star: egg hatching at 10:14 at jw:"
  	egg_text += "\n`#{Bot::PREFIX}egg jw, 10:14`"
  	egg_text += "\nTo report a 2:star: egg hatching in 8 minutes at long song:"
		egg_text += "\n`#{Bot::PREFIX}egg long song, 8, 2`"
  	egg_text += "\nAll pending eggs can be viewed in a pinned message in the Raids channel."
  	egg_text += "\nThere is no edit function; use `raid` to report the raid boss when egg hatches or `rm` to remove a mis-reported egg."
    Bot::CommandCategories['reporting'].push :egg => egg_text    
  end
end
