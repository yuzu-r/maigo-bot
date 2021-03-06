module Bot::TrainCommands
  module Conductor
    extend Discordrb::Commands::CommandContainer
    command :conductor do |_event, conductor|
    	train = Bot::Trains[_event.server.id]
			train.conductor = conductor
			if train.conductor
				_event.respond "You made #{conductor} the point of contact for the train."
			else
				_event.respond "There is no conductor right now."
			end
    end
  end
end
