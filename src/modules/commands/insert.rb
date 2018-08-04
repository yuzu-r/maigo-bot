module Bot::DiscordCommands
  module Insert
    extend Discordrb::Commands::CommandContainer
    command :insert do |_event|
			raids = find_active_raids(_event.server.id.to_s)
			if !raids || raids.count == 0
				no_message = _event.bot.send_message(_event.channel.id, 'There are no raids to insert. Bah.')
				_event.message.delete
				sleep 3
				no_message.delete
			else
				raid_id = 1
				route_text = "Enter the raid number you wish to insert into the route, or 0 to cancel.\n--\n0) **Cancel route insert**"
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
				response = _event.message.await!(timeout: 25, user: _event.user)
				if response 
					target_raid = response.content.to_i
					if target_raid == 0
						cancel_message = _event.respond "Insert cancelled - no changes made. Cleaning up and bugging out!"
						initial_message.delete
						response.message.delete
						_event.message.delete
						sleep 3
						cancel_message.delete
					else
						_event.respond "You want to insert #{raids[target_raid-1]['gym']} (**#{raids[target_raid-1]['despawn_time'].strftime("%-I:%M")}**) into the existing route."
						_event.respond "This raid should come BEFORE:"
						_event.respond "0) **Cancel route insert**"
						_event.respond train.list
						_event.respond "#{train.count + 1} ) **Add to end of current route**"
						insert_response = event.message.await!(timeout: 20, user: _event.user)
						if insert_response
							insert_before = insert_response.content.to_i
							if insert_before == 0
								_event.respond "Insert cancelled - no changes made."
							else
								new_route = train.insert(insert_before, raids[target_raid-1]['_id'])
								_event.respond "The route is now #{new_route}."
							end
						else
							timeout_message = _event.respond "Timeout - insert cancelled."
						end
					end
				else
					timeout_message = _event.respond "Timeout - insert cancelled."
					initial_message.delete
					_event.message.delete
					sleep 3
					timeout_message.delete
				end
			end
    end
  end
end
