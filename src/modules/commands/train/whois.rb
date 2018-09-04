module Bot::TrainCommands
  module Whois
    extend Discordrb::Commands::CommandContainer
    command :whois do |_event|
    	train = Bot::Trains[_event.server.id]
			if train.conductor
				_event.respond "The train conductor is #{train.conductor}. Use `,conductor username` to change."
			else
				_event.respond "There is no conductor right now. Use `,conductor username` to set one."
			end
    end
  end
end
