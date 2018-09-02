module Bot::TrainCommands
  module Data
    extend Discordrb::Commands::CommandContainer
    if Bot::ENV =='development'
	    command :data do |_event|
				# creates 7 semi-random egg/raid events
				# development only!
					insert_test(_event.server)
					silent_update(_event.server, _event.bot)
					_event.message.react("✅")
				#end
	    end
  	end
  end
end
