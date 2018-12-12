module Bot::ReportingCommands
  module Hatch
    extend Discordrb::Commands::CommandContainer
    command(:hatch, min_args: 1, max_args: 1, usage: 'hatch <boss>', description: 'update an egg report to a raid report') do |_event, boss|

      if boss.include?('@')
        error_msg = "No tags or mentions are allowed in the hatch command."
        _event.respond _event.user.mention + ' ' + error_msg
        return
      end

    	active_eggs = find_active_eggs(_event.server.id.to_s)
    	if !active_eggs || active_eggs.count == 0
    		no_eggs_message = _event.bot.send_message(_event.channel.id, 'No eggs found to update.')
    		sleep 3
    		_event.message.delete
    		no_eggs_message.delete
    	else
    		tz = TZInfo::Timezone.get('America/Los_Angeles')
    		egg_id = 1
    		update_text = "Enter the number of the egg that hatched, or 0 to cancel.\n0) **Cancel update request**"
    		active_eggs.each do |egg|
    			convert_hatch_time = tz.utc_to_local(egg['hatch_time']).strftime("%-I:%M")
    			convert_despawn_time = convert_despawn_time = tz.utc_to_local(egg['despawn_time']).strftime("%-I:%M")
    			update_text += "\n#{egg_id.to_s}) #{egg['tier']}* (#{convert_hatch_time} to **#{convert_despawn_time}**) @ #{egg['gym']}"
    			egg_id += 1
    		end
    		initial_message = _event.respond update_text
    		response = _event.message.await!(timeout: 15, user: _event.user)
    		if response
    			target_egg = response.content.to_i
    			if target_egg == 0
						cancel_message = _event.respond "Update cancelled - no changes made. Until next time!"
						sleep 3
						initial_message.delete
						response.message.delete
						_event.message.delete
						cancel_message.delete
					elsif target_egg > egg_id - 1
						invalid_message = _event.respond "Can't find that egg to update. Maybe another time!"
						sleep 3
						initial_message.delete
						response.message.delete
						_event.message.delete
						invalid_message.delete
    			else
    				egg_update_message = _event.respond "Egg #{target_egg.to_s} has hatched #{boss.downcase}, updating..."
    				db_response = hatch_egg(_event.server, _event.user, active_eggs[target_egg-1]["_id"], boss)
    				if !db_response || db_response.n != 1
    					fallback_msg = "error trying to update egg to raid"
              log_command(_event, 'hatch', false, fallback_msg)
    				else
              sort_and_pin(_event)
              log_command(_event, 'hatch', true, "Could not log hatch command to database!")
    					sleep 3
							initial_message.delete
							response.message.delete
							_event.message.delete
    					egg_update_message.delete
    				end
    			end
    		else
					timeout_message = _event.respond "Timeout - nothing will be updated."
					sleep 3
					initial_message.delete
					_event.message.delete
					timeout_message.delete
    		end
    	end
		return
    end
    hatch_text = "\n**Hatch Command**"
    hatch_text += "\n`#{Bot::PREFIX}hatch [boss]`"
  	hatch_text += "\nUse this command to add the raid boss to a previously reported egg after it hatches."
    hatch_text += "\nA numbered list of the eggs that were reported earlier will appear."
    hatch_text += "\nChoose the number of the egg that hatched (or 0 to cancel)."
    hatch_text += "\nThe command times out after 15 seconds of inactivity."
    hatch_text += "\nDo not use mentions (@) for the boss name."

    Bot::CommandCategories['reporting'].push :hatch => hatch_text
  end
end
