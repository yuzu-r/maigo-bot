module Bot::DiscordCommands
  module Help
    extend Discordrb::Commands::CommandContainer
    command :help do |_event|
    	gym_finder_text = "**Gym Finder**"
    	gym_finder_text += "\nType `#{Bot::PREFIX}whereis` and a gym name or nickname to look up its location. "
    	gym_finder_text += "\nTry `#{Bot::PREFIX}whereis happy donuts` to see it in action. "
    	gym_finder_text += "\nIt is not case sensitive. In most cases, it can guess an incomplete name, but not typo-ed names. "
    	gym_finder_text += "In other words, `#{Bot::PREFIX}whereis donut` will work, but `#{Bot::PREFIX}whereis hapy donts` will not. "
    	gym_finder_text += "If the entered name isn\'t unique, maigo-helper will return a list of suggestions to narrow down your search."
    	gym_finder_text += "\nType `#{Bot::PREFIX}exgyms` to see a listing of El Cerrito/Albany gyms known to hold ex raids."
    	_event.send_message(gym_finder_text)

		  _event << "\n**Raid Reporting**"
		  _event << "`#{Bot::PREFIX}active` returns a list of active and pending raids, sorted by despawn time."
		  _event << "`#{Bot::PREFIX}egg [gym], [hatch time OR minutes to hatch], [optional tier; default is 5]`"
		  _event << "`#{Bot::PREFIX}raid [gym], [minutes remaining to despawn], [boss]`"
		  _event << "`#{Bot::PREFIX}rm` launches an interactive menu to remove a mis-reported egg or raid."
		  _event << "\nExamples"
		  _event << "`#{Bot::PREFIX}egg jw, 10:14` (5* egg hatching at 10:14)"
		  _event << "`#{Bot::PREFIX}egg long song, 8, 2` (2* egg hatching in 8 minutes)"
		  _event << "`#{Bot::PREFIX}raid frog, 42, kyogre`"
		  _event << "\n**Misc and Experimental Commands**"
		  _event << "`#{Bot::PREFIX}leaderboard` returns a list of most active egg/raid reporters."
		  _event << "`#{Bot::PREFIX}whenis [minutes]` calculates what time it is `minutes` from now."
			fallback_msg = "Could not log help command to database!"
			log_command(_event, 'help', true, fallback_msg)
    end
  end
end
