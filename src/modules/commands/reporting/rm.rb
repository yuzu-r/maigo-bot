module Bot::ReportingCommands
  module Rm
    extend Discordrb::Commands::CommandContainer
    command(:rm, description: 'remove a mis-reported egg or raid')do |_event|
			raids = find_active_raids(_event.server.id.to_s)
			if !raids || raids.count == 0
				no_message = _event.bot.send_message(_event.channel.id, 'There is nothing to remove.')
				_event.message.delete
				sleep 3
				no_message.delete
			else
				raid_id = 1
				delete_text = "Enter the number of the raid/egg you wish to remove, or 0 to cancel.\n0) **Cancel delete request**"
				raids.each do |raid|
			  	if raid['tier']
						delete_text += "\n#{raid_id.to_s}) #{raid['tier']}* (#{raid['hatch_time'].strftime("%-I:%M")} to **#{raid['despawn_time'].strftime("%-I:%M")}**) @ #{raid['gym']}"
					else
						delete_text += "\n#{raid_id.to_s}) #{raid['boss'].capitalize} (**#{raid['despawn_time'].strftime("%-I:%M")}**) @ #{raid['gym']} "
					end
					raid_id += 1
				end
				initial_message = _event.respond delete_text
				response = _event.message.await!(timeout: 10, user: _event.user)
				if response 
					target_raid = response.content.to_i
					if target_raid == 0
						cancel_message = _event.respond "Remove cancelled - no changes made. Cleaning up and bugging out!"
						initial_message.delete
						response.message.delete
						_event.message.delete
						sleep 3
						cancel_message.delete
					elsif target_raid > raid_id - 1
						invalid_message = _event.respond "Can't find that raid to remove. Cleaning up and carrying on."
						initial_message.delete
						response.message.delete
						_event.message.delete
						sleep 3
						invalid_message.delete
					else
						raid_delete_message = _event.respond "ok, I will delete raid #{target_raid.to_s}."
						db_response = delete_raid(raids[target_raid-1]["_id"])
						if !db_response || db_response.n != 1
							puts "Unable to remove raid."
						else
							initial_message.delete
							response.message.delete
							_event.message.delete
							#sort_and_pin(_event, bot)
							silent_update(_event.server, _event.bot)
							sleep 3
							raid_delete_message.delete
						end
					end
				else
					timeout_message = _event.respond "Timeout - nothing will be deleted."
					initial_message.delete
					_event.message.delete
					sleep 3
					timeout_message.delete
				end
			end
    end
    rm_text = "\n**Rm Command**"
    rm_text += "\n`#{Bot::PREFIX}rm`"
  	rm_text += "\nThis command will launch an interactive session to remove a mis-reported egg or raid."
  	rm_text += "\nAfter typing the command, a list of active and pending raids will appear."
  	rm_text += "\nEnter the number that corresponds to the raid/egg that was mis-reported."
  	rm_text += "\nThe command will timeout after 10 seconds if there is no response."
    Bot::CommandCategories['reporting'].push :rm => rm_text        
  end
end
