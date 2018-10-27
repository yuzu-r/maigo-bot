module Bot::WhereisCommands
  module Whereis
    extend Discordrb::Commands::CommandContainer
    	command(:whereis, min_args: 1, description: 'find a gym') do |_event, *gym|
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
					emoji = _event.bot.find_emoji(Bot::LEGENDARY_EMOJI)
					emoji_text = emoji ? emoji.mention : ':exclamation:'
					_event << emoji_text + ' EX Raid Location!'
				end
				_event << message['address']
				if message['landmark']
					_event << 'Near: ' + message['landmark']
				end
				# suppress the map preview for brevity
				google_maps = message['gmap'] ? '<' + message['gmap'] + '>' : nil
				fallback_msg = "Could not log successful search for #{search_term} to database!"
				log_command(_event, 'whereis', true, fallback_msg, search_term)
				_event << google_maps
			else
				# either multiple gyms returned, or no gyms found
				fallback_msg = "Could not log unsuccessful search for #{search_term} to database!"
				log_command(_event, 'whereis', false, fallback_msg, search_term)				
				message
			end
    end
  	whereis_text = "\nType `#{Bot::PREFIX}whereis` and a gym name or nickname to look up its location. "
  	whereis_text += "\nTry `#{Bot::PREFIX}whereis happy donuts` to see it in action. "
  	whereis_text += "\nIt is not case sensitive. In most cases, it can guess an incomplete name, but not typo-ed names. "
  	whereis_text += "In other words, `#{Bot::PREFIX}whereis donut` will work, but `#{Bot::PREFIX}whereis hapy donts` will not. "
  	whereis_text += "If the entered name isn\'t unique, maigo-helper will return a list of suggestions to narrow down your search."    
    Bot::CommandCategories['lookup'].push :whereis => whereis_text
  end
end
