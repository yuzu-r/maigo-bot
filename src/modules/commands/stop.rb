module Bot::DiscordCommands
  module Stop
    extend Discordrb::Commands::CommandContainer
    command :stop do |_event|
			_event.respond train.stop    	
    end
  end
end
