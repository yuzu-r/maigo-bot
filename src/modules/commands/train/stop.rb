module Bot::TrainCommands
  module Stop
    extend Discordrb::Commands::CommandContainer
    command :stop do |_event|
    	train = Bot::Trains[_event.server.id]
			_event.respond train.stop    	
    end
  end
end
