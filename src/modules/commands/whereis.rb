module Bot::DiscordCommands
  module Whereis
    extend Discordrb::Commands::CommandContainer
    command(:whereis, min_args: 1) do |_event, *gym|
			search_term = gym.join(' ')
			message = lookup(search_term)
			if message['name']
				if message['name'].downcase != search_term.downcase
					title = search_term + ', aka ' + message['name']
				else
					title = message['name']
				end
				_event << title
				if message['is_ex_eligible']
					_event << 'EX Raid Location!'
				end
				_event << message['address']
				if message['landmark']
					_event << 'Near: ' + message['landmark']
				end
				# suppress the map preview for brevity
				google_maps = message['gmap'] ? '<' + message['gmap'] + '>' : nil
				if Bot::LOGGING == 'true'
					response = log(_event.server.id, _event.user.id, 'whereis', search_term, true)
					if !response || response.n != 1
						puts "could not log whereis to database, successful search for #{search_term}"
					end
				end
				_event << google_maps
			else
				# either multiple gyms returned, or no gyms found
				if Bot::LOGGING == 'true'
					response = log(_event.server.id, _event.user.id, 'whereis', search_term, false)
			 		if !response || response.n != 1
			 			puts "could not log whereis to database, unsuccessful search for #{search_term}"
					end
				end
				message
			end
    end
  end
end
