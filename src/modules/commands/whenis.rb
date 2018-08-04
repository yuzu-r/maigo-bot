module Bot::DiscordCommands
  module Whenis
    extend Discordrb::Commands::CommandContainer
    command :whenis do |_event, mins|
			tz = TZInfo::Timezone.get('America/Los_Angeles')
			_event.respond "#{mins} minutes from now is #{tz.utc_to_local(Time.now + mins.to_i*60).strftime("%-I:%M")}"    	
			fallback_msg = "Could not log time command to database!"
			log_command(_event, 'whenis', true, fallback_msg)
    end
  end
end
