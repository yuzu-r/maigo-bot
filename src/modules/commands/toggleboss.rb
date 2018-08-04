module Bot::DiscordCommands
  module Toggleboss
    extend Discordrb::Commands::CommandContainer
    command :toggleboss do |_event|
			boss_text = train.toggle_boss ? "will" : "will not"
			_event.respond "The boss #{boss_text} show in the route information."
    end
  end
end
