module Bot::HelpCommands
  module Help
    extend Discordrb::Commands::CommandContainer
      command :help do |_event|
    end
  end
end
=begin
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
=end
end
