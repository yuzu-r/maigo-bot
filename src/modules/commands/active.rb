module Bot::DiscordCommands
  module Active
    extend Discordrb::Commands::CommandContainer
    command :active do |_event|
			sort_and_pin(_event)
			return    	
    end
  end
end
