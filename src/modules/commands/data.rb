module Bot::DiscordCommands
  module Data
    extend Discordrb::Commands::CommandContainer
    command :data do |_event|
			# creates 7 semi-random egg/raid events
			insert_test(_event.server)
			silent_update(_event.server, _event.bot)
			_event.message.react("✅")
    end
  end
end
