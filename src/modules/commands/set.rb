module Bot::DiscordCommands
  module Set
    extend Discordrb::Commands::CommandContainer
    command :set do |_event, *raid_id|
			raids = find_active_raids(_event.server.id.to_s)
			if !raids || raids.count == 0
				no_message = _event.bot.send_message(_event.channel.id, 'There are no raids to for the train to battle. Pfui.')
				_event.message.delete
				sleep 3
				no_message.delete
			else
				raid_id = 1
				route_text = "Enter the raid numbers in order the train will visit them, or 0 to cancel.\n--\n0) **Cancel route creation**"
				raids.each do |raid|
			  	if raid['tier']
						route_text += "\n#{raid_id.to_s}) #{raid['tier']}* (#{raid['hatch_time'].strftime("%-I:%M")} to **#{raid['despawn_time'].strftime("%-I:%M")}**) @ #{raid['gym']}"
					else
						route_text += "\n#{raid_id.to_s}) #{raid['boss'].capitalize} (**#{raid['despawn_time'].strftime("%-I:%M")}**) @ #{raid['gym']} "
					end
					raid_id += 1
				end
				route_text += "\n\nCurrent route: #{train.show}"
				initial_message = _event.respond route_text
				response = _event.message.await!(timeout: 30, user: _event.user)
				if response 
					target_raid = response.content.to_i
					if target_raid == 0
						cancel_message = _event.respond "Routing cancelled - no changes made. Cleaning up and bugging out!"
						initial_message.delete
						response.message.delete
						_event.message.delete
						sleep 3
						cancel_message.delete
					else
						train.set(response.content, raids)
					end
				else
					timeout_message = _event.respond "Timeout - no additions will be made to the route."
					initial_message.delete
					_event.message.delete
					sleep 3
					timeout_message.delete
				end
			end
    end
  end
end
