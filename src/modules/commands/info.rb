module Bot::DiscordCommands
  module Info
    extend Discordrb::Commands::CommandContainer
    command :info do |_event|
    	train = Bot::Trains[_event.server.id]
			_event.respond "Anyone is welcome to meet or join the train at any time!"
			if train.conductor
				_event.respond "Please mention #{train.conductor} if you plan to join so we know to look for you!"	
			else
				_event.respond "Please comment in discord if you plan to join so we know to look for you!"
			end    	
    end
  end
end
