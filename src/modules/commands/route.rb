module Bot::DiscordCommands
  module Route
    extend Discordrb::Commands::CommandContainer
    command :route do |_event|
  	train = Bot::Trains[_event.server.id]
		# this command should be runnable by anyone, in the raids channel (or other default)
			if train.count > 0
				_event.respond "The train is on the move!\nPlanned stops: #{train.show}"
			else
				_event.respond "The train has no planned destination right now.\nHelp the train out by calling out eggs and raids that you see."
			end
    end
  end
end
