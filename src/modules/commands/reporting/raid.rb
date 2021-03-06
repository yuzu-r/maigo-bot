module Bot::ReportingCommands
  module Raid
    extend Discordrb::Commands::CommandContainer
    command(:raid, description: 'report a raid') do |_event, *raid_info|

			server_id = _event.server.id
			username = _event.user.display_name

			parsed_raid_data = comma_parse(raid_info)
			if parsed_raid_data.count != 3
				error_msg = "Usage: #{Bot::PREFIX}raid *gym*, *minutes remaining*, *boss* (separated by commas)"
				_event.respond _event.user.mention + ' ' + error_msg
				delete_message_queue(Bot::DeleteRaidMessageQueue[server_id], _event, false)
				return		
			else
				gym, minutes_left, boss = parsed_raid_data
				time_ok = minutes_left =~ /\D/
				if !time_ok.nil? # do not accept : or anything other than digits for raids
					error_msg = "The raid command only accepts minutes remaining (do not include seconds)\n"
					error_msg += "Usage: #{Bot::PREFIX}raid *gym*, *minutes remaining*, *boss* (separated by commas)"
					_event.respond _event.user.mention + ' ' + error_msg
					delete_message_queue(Bot::DeleteRaidMessageQueue[server_id], _event, false)
					return
				end
				# no tags in the boss like <@!342468337999151116> or @here
				if boss.include?('@') || gym.include?('@')
					error_msg = "No tags or mentions are allowed in the raid report."
					_event.respond _event.user.mention + ' ' + error_msg
					delete_message_queue(Bot::DeleteRaidMessageQueue[server_id], _event, false)
					return
				end
			end

			despawn_time = Time.now + minutes_left.to_i * 60

			response = register_raid(gym, despawn_time, boss, username, _event.server.id, _event.user.id)
			is_success = true
			if !response || response.n != 1
				puts "could not log raid to database"
				is_success = false
			end
			sort_and_pin(_event)
			delete_message_queue(Bot::DeleteRaidMessageQueue[server_id], _event)
			fallback_msg = "Could not log raid command to database!"
			log_command(_event, 'raid', is_success, fallback_msg)
			return
    end
    raid_text = <<~RAID_TEXT
    	**Raid Reporting**
    	`#{Bot::PREFIX}raid [gym], [minutes remaining to despawn], [boss]`
    	To report a kyogre raid with 42 minutes remaining at frog habitat:
    	`#{Bot::PREFIX}raid frog, 42, kyogre`
    	All active raids can be viewed in a pinned message in the Raids channel.
    RAID_TEXT
    Bot::CommandCategories['reporting'].push :raid => raid_text
  end
end
