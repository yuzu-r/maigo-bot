module Bot::DiscordCommands
  module Update
    extend Discordrb::Commands::CommandContainer
    command :update do |_event|
			sort_and_pin(event, bot)
			return    	
    end
  end
end
