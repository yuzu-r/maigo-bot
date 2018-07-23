module Bot::DiscordCommands
  module Help
    extend Discordrb::Commands::CommandContainer
    command :help do |_event|
		  _event << "Type ***#{Bot::PREFIX}whereis*** and a gym name or nickname to look up its location."
		  _event << "Try ***#{Bot::PREFIX}whereis happy donuts*** to see it in action."
		  _event << "It is not case sensitive. In most cases, it can guess an incomplete name, not typo-ed names."
		  _event << "In other words, ***#{Bot::PREFIX}whereis donut*** will work, but ***#{Bot::PREFIX}whereis hapy donts*** will not."
		  _event << "If the entered name isn\'t unique, maigo-helper will return a list of suggestions to narrow down your search."
		  _event << "\nType ***#{Bot::PREFIX}exgyms*** to see a listing of El Cerrito/Albany gyms known to hold ex raids."
			fallback_msg = "Could not log help command to database!"
			log_command(_event, 'help', true, fallback_msg)
    end
  end
end
