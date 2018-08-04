module Bot::DiscordCommands
  module Skip
    extend Discordrb::Commands::CommandContainer
    command :skip do |_event, position|
			# position is optional
			train = Bot::Trains[_event.server.id]			
			if /\d/ === position
				_event.respond train.skip(position.to_i)
			else
				# interactively determine which raid to remove
				# this needs to be cleaned up more thoroughly after command runs
				_event.respond "You want to skip a stop on the route. Which one?"
				_event.respond "0) **Cancel skip entry**"
				_event.respond train.list
				response = _event.message.await!(timeout: 20, user: _event.user)
				if response 
					raid_index = response.content.to_i
					if raid_index == 0
						cancel_message = _event.respond "Skip cancelled - no changes made. Cleaning up and bugging out!"
						sleep 3
						_event.message.delete
						response.message.delete
						cancel_message.delete
					else
						_event.respond train.skip(raid_index)
					end
				else
					timeout_message = _event.respond "Timeout - skip cancelled."
					sleep 3
					_event.message.delete
					timeout_message.delete			
					return
				end
			end    	
    end
  end
end
