module Bot::DiscordCommands
  module Raid
    extend Discordrb::Commands::CommandContainer
    command(:raid, min_args: 1, description: 'report a raid') do |_event, *raid_info|
			raid_channel = get_raids_channel(_event.server)
			username = _event.user.display_name

			parsed_raid_data = comma_parse(raid_info)
			if parsed_raid_data.count != 3
				error_msg = "Usage: ,raid <gym>,<minutes remaining>, <boss> (separated by commas)"
				_event.respond _event.user.mention + ' ' + error_msg
				return		
			else
				gym, minutes_left, boss = parsed_raid_data
				time_ok = minutes_left =~ /\D/
				if !time_ok.nil? # do not accept : or anything other than digits for raids
					error_msg = "The raid command only accepts minutes remaining (do not include seconds)"
					_event.respond _event.user.mention + ' ' + error_msg
					return
				end
			end

			tz = TZInfo::Timezone.get('America/Los_Angeles')
			despawn_time = tz.utc_to_local(Time.now + minutes_left.to_i*60)

			gym_data = lookup(gym)
			if gym_data['gmap']
				gym_info = '[' + gym + ']' + '(' + gym_data['gmap'] + ')'
			else
				gym_info = gym
			end

			response = register_raid(gym, despawn_time, boss, username, _event.server.id)
			is_success = true
			if !response || response.n != 1
				puts "could not log raid to database"
				is_success = false
			end
			embed = Discordrb::Webhooks::Embed.new
			embed.title = "**#{boss.capitalize} raid until #{despawn_time.strftime("%-I:%M")}! (#{minutes_left} mins left)**"
			embed.color = 15236612
			embed.description = "Gym: #{gym_info} (reported by #{username})"
			_event.bot.send_message(raid_channel.id, '',false, embed)
			silent_update(_event.server, _event.bot)
			_event.message.react("✅")
			fallback_msg = "Could not log raid command to database!"
			log_command(_event, 'raid', is_success, fallback_msg)
			return
    end
  end
end
