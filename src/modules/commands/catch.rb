module Bot::DiscordCommands
  module Catch
    extend Discordrb::Commands::CommandContainer
    command :catch do |_event|
    	train = Bot::Trains[_event.server.id]
			if train.count == 0
				_event.respond "There is nothing for the train to catch."
			else
				raid = train.first
				new_route = train.next
				_event.respond "The train is catching at #{raid['gym']}.\n Next stops: #{new_route}"
			end
    end
  end
end
